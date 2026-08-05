import json
import uuid
from typing import Any

from openai import OpenAI
from sqlalchemy.orm import Session

from ai.prompts.system import DOCTOR_SYSTEM_PROMPT, SYSTEM_PROMPT
from ai.tools.appointments import TOOL_DEFINITIONS, ToolExecutor
from apps.api.config import settings
from apps.api.models import Conversation, User, UserRole


class ReceptionistAgent:
    def __init__(self, db: Session):
        self.db = db
        self.client = OpenAI(api_key=settings.openai_api_key) if settings.openai_api_key else None

    async def handle_message(
        self,
        message: str,
        session_id: str | None = None,
        patient_id: int | None = None,
        user: User | None = None,
    ) -> dict[str, Any]:
        session_id = session_id or str(uuid.uuid4())
        conversation = (
            self.db.query(Conversation).filter(Conversation.session_id == session_id).first()
        )
        if not conversation:
            conversation = Conversation(
                session_id=session_id,
                patient_id=patient_id,
                messages=[],
            )
            self.db.add(conversation)
            self.db.commit()
            self.db.refresh(conversation)

        messages = list(conversation.messages or [])
        messages.append({"role": "user", "content": message})

        system_prompt = DOCTOR_SYSTEM_PROMPT if user and user.role == UserRole.DOCTOR else SYSTEM_PROMPT
        if patient_id:
            system_prompt += f"\nCurrent patient ID: {patient_id}"

        tool_calls_made: list[str] = []
        executor = ToolExecutor(self.db, conversation_id=conversation.id)

        if self.client and not settings.demo_mode:
            response_text = await self._run_openai_agent(
                system_prompt, messages, executor, tool_calls_made
            )
        else:
            response_text = self._run_demo_agent(message, executor, tool_calls_made, patient_id)

        messages.append({"role": "assistant", "content": response_text})
        conversation.messages = messages
        conversation.escalated = executor.escalated
        self.db.commit()

        return {
            "session_id": session_id,
            "message": response_text,
            "tool_calls_made": tool_calls_made,
            "escalated": executor.escalated,
        }

    async def _run_openai_agent(
        self,
        system_prompt: str,
        messages: list[dict],
        executor: ToolExecutor,
        tool_calls_made: list[str],
    ) -> str:
        openai_messages = [{"role": "system", "content": system_prompt}] + messages

        for _ in range(5):
            response = self.client.chat.completions.create(
                model="gpt-4o-mini",
                messages=openai_messages,
                tools=TOOL_DEFINITIONS,
                tool_choice="auto",
            )
            choice = response.choices[0]
            if choice.finish_reason == "tool_calls" and choice.message.tool_calls:
                openai_messages.append(choice.message)
                for tool_call in choice.message.tool_calls:
                    name = tool_call.function.name
                    args = json.loads(tool_call.function.arguments)
                    tool_calls_made.append(name)
                    result = executor.execute(name, args)
                    openai_messages.append(
                        {
                            "role": "tool",
                            "tool_call_id": tool_call.id,
                            "content": result,
                        }
                    )
            else:
                return choice.message.content or "I'm sorry, I couldn't process that request."

        return "I need a moment — let me connect you with a staff member."

    def _run_demo_agent(
        self,
        message: str,
        executor: ToolExecutor,
        tool_calls_made: list[str],
        patient_id: int | None,
    ) -> str:
        lower = message.lower()

        emergency_keywords = [
            "chest pain", "can't breathe", "severe bleeding", "suicidal", "heart attack", "stroke"
        ]
        if any(kw in lower for kw in emergency_keywords):
            tool_calls_made.append("escalate_to_human")
            return executor.execute(
                "escalate_to_human",
                {
                    "reason": f"Patient reported: {message}",
                    "urgency": "emergency",
                    "patient_id": patient_id,
                },
            )

        if any(kw in lower for kw in ["hours", "location", "address", "where", "open"]):
            return (
                "CityCare General Hospital is located at 123 Medical Center Drive, Springfield, IL 62701. "
                "We're open Monday–Friday 8:00 AM – 6:00 PM and Saturday 9:00 AM – 1:00 PM. "
                "You can reach us at (555) 123-4567."
            )

        if any(kw in lower for kw in ["insurance", "accept"]):
            return (
                "We accept Blue Cross, Aetna, UnitedHealthcare, Medicare, and Medicaid. "
                "Please bring your insurance card to your appointment."
            )

        if any(kw in lower for kw in ["cardio", "heart"]):
            tool_calls_made.append("search_doctors")
            result = executor.execute("search_doctors", {"specialty": "Cardiology"})
            return f"Here are our cardiology specialists:\n\n{result}\n\nWould you like to check availability for one of them?"

        if any(kw in lower for kw in ["pediatric", "child", "kid"]):
            tool_calls_made.append("search_doctors")
            result = executor.execute("search_doctors", {"specialty": "Pediatrics"})
            return f"Here are our pediatric specialists:\n\n{result}\n\nWould you like to book an appointment?"

        if any(kw in lower for kw in ["doctor", "dr.", "specialist", "department"]):
            tool_calls_made.append("search_doctors")
            result = executor.execute("search_doctors", {})
            return f"Here are our available doctors:\n\n{result}\n\nWhich doctor would you like to see, and what date works for you?"

        if any(kw in lower for kw in ["available", "availability", "slot", "time"]):
            tool_calls_made.append("check_availability")
            from datetime import date, timedelta

            tomorrow = (date.today() + timedelta(days=1)).isoformat()
            result = executor.execute("check_availability", {"doctor_id": 1, "date_from": tomorrow})
            return f"Here are available slots for Dr. Smith:\n\n{result}\n\nTo book, please tell me your patient ID and preferred slot number."

        if any(kw in lower for kw in ["book", "schedule", "appointment"]):
            if patient_id:
                tool_calls_made.append("check_availability")
                from datetime import date, timedelta

                tomorrow = (date.today() + timedelta(days=1)).isoformat()
                avail = executor.execute(
                    "check_availability", {"doctor_id": 1, "date_from": tomorrow}
                )
                tool_calls_made.append("book_appointment")
                book_result = executor.execute(
                    "book_appointment",
                    {
                        "patient_id": patient_id,
                        "doctor_id": 1,
                        "slot_id": 1,
                        "reason_for_visit": message,
                    },
                )
                return f"{book_result}\n\nAvailable slots were:\n{avail}"
            return (
                "I'd be happy to help you book an appointment! "
                "Please provide your email or patient ID so I can look up your record, "
                "and let me know which doctor or specialty you'd like to see."
            )

        if any(kw in lower for kw in ["my appointment", "upcoming", "when is"]):
            if patient_id:
                tool_calls_made.append("get_patient_appointments")
                result = executor.execute("get_patient_appointments", {"patient_id": patient_id})
                return result
            return "Please provide your patient ID or email so I can look up your appointments."

        if any(kw in lower for kw in ["human", "speak to", "receptionist", "help me"]):
            tool_calls_made.append("escalate_to_human")
            return executor.execute(
                "escalate_to_human",
                {
                    "reason": message,
                    "urgency": "medium",
                    "patient_id": patient_id,
                },
            )

        return (
            "Hello! I'm the AI receptionist at CityCare General Hospital. I can help you with:\n"
            "• Booking appointments\n"
            "• Finding the right doctor or department\n"
            "• Hospital hours and location\n"
            "• Insurance questions\n\n"
            "How can I assist you today?"
        )
