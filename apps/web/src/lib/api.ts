const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";

export interface User {
  id: number;
  email: string;
  full_name: string;
  role: string;
}

export interface AuthResponse {
  access_token: string;
  token_type: string;
  user: User;
}

export interface ChatResponse {
  session_id: string;
  message: string;
  tool_calls_made: string[];
  escalated: boolean;
}

export interface Appointment {
  id: number;
  patient_id: number;
  doctor_id: number;
  slot_id: number | null;
  scheduled_at: string;
  status: string;
  reason_for_visit: string | null;
  notes: string | null;
  patient_name: string | null;
  doctor_name: string | null;
  has_intake: boolean;
}

export interface Doctor {
  id: number;
  first_name: string;
  last_name: string;
  specialty: string;
  department: string;
}

export interface Escalation {
  id: number;
  reason: string;
  urgency: string;
  resolved: boolean;
  patient_name: string | null;
  created_at: string;
}

export interface IntakeForm {
  id: number;
  appointment_id: number;
  symptoms_summary: string | null;
  medications: string | null;
  allergies: string | null;
  additional_notes: string | null;
  prep_summary: string | null;
}

function getToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem("token");
}

async function apiFetch<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = getToken();
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    ...(options.headers as Record<string, string>),
  };
  if (token) headers["Authorization"] = `Bearer ${token}`;

  const res = await fetch(`${API_URL}${path}`, { ...options, headers });
  if (!res.ok) {
    const err = await res.json().catch(() => ({ detail: res.statusText }));
    throw new Error(err.detail || "Request failed");
  }
  return res.json();
}

export async function login(email: string, password: string): Promise<AuthResponse> {
  const data = await apiFetch<AuthResponse>("/api/auth/login", {
    method: "POST",
    body: JSON.stringify({ email, password }),
  });
  localStorage.setItem("token", data.access_token);
  localStorage.setItem("user", JSON.stringify(data.user));
  return data;
}

export function logout() {
  localStorage.removeItem("token");
  localStorage.removeItem("user");
}

export function getStoredUser(): User | null {
  if (typeof window === "undefined") return null;
  const raw = localStorage.getItem("user");
  return raw ? JSON.parse(raw) : null;
}

export async function sendChat(
  message: string,
  sessionId?: string,
  patientId?: number
): Promise<ChatResponse> {
  return apiFetch<ChatResponse>("/api/chat", {
    method: "POST",
    body: JSON.stringify({ message, session_id: sessionId, patient_id: patientId }),
  });
}

export async function getDoctors(): Promise<Doctor[]> {
  return apiFetch<Doctor[]>("/api/doctors");
}

export async function getDoctorSchedule(doctorId: number, date?: string): Promise<Appointment[]> {
  const params = date ? `?schedule_date=${date}` : "";
  return apiFetch<Appointment[]>(`/api/doctors/${doctorId}/schedule${params}`);
}

export async function getEscalations(): Promise<Escalation[]> {
  return apiFetch<Escalation[]>("/api/escalations?resolved=false");
}

export async function resolveEscalation(id: number): Promise<void> {
  await apiFetch(`/api/escalations/${id}/resolve`, { method: "PATCH" });
}

export async function updateAppointment(
  id: number,
  data: { status?: string; notes?: string }
): Promise<Appointment> {
  return apiFetch<Appointment>(`/api/appointments/${id}`, {
    method: "PATCH",
    body: JSON.stringify(data),
  });
}

export async function submitIntake(
  appointmentId: number,
  data: {
    symptoms_summary?: string;
    medications?: string;
    allergies?: string;
    additional_notes?: string;
  }
): Promise<IntakeForm> {
  return apiFetch<IntakeForm>(`/api/appointments/${appointmentId}/intake`, {
    method: "POST",
    body: JSON.stringify(data),
  });
}

export async function getIntake(appointmentId: number): Promise<IntakeForm> {
  return apiFetch<IntakeForm>(`/api/appointments/${appointmentId}/intake`);
}

export async function getAppointments(params?: {
  doctor_id?: number;
  patient_id?: number;
}): Promise<Appointment[]> {
  const search = new URLSearchParams();
  if (params?.doctor_id) search.set("doctor_id", String(params.doctor_id));
  if (params?.patient_id) search.set("patient_id", String(params.patient_id));
  const qs = search.toString();
  return apiFetch<Appointment[]>(`/api/appointments${qs ? `?${qs}` : ""}`);
}
