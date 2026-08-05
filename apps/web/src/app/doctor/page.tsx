"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import {
  Appointment,
  Doctor,
  Escalation,
  getDoctorSchedule,
  getDoctors,
  getEscalations,
  getIntake,
  getStoredUser,
  logout,
  resolveEscalation,
  updateAppointment,
} from "@/lib/api";

export default function DoctorDashboard() {
  const [doctors, setDoctors] = useState<Doctor[]>([]);
  const [selectedDoctorId, setSelectedDoctorId] = useState<number>(1);
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [escalations, setEscalations] = useState<Escalation[]>([]);
  const [prepSummaries, setPrepSummaries] = useState<Record<number, string>>({});
  const [selectedDate, setSelectedDate] = useState(new Date().toISOString().split("T")[0]);
  const [loading, setLoading] = useState(true);
  const user = getStoredUser();

  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      const [docs, schedule, esc] = await Promise.all([
        getDoctors(),
        getDoctorSchedule(selectedDoctorId, selectedDate),
        getEscalations(),
      ]);
      setDoctors(docs);
      setAppointments(schedule);
      setEscalations(esc);

      const summaries: Record<number, string> = {};
      for (const apt of schedule) {
        if (apt.has_intake) {
          try {
            const intake = await getIntake(apt.id);
            if (intake.prep_summary) summaries[apt.id] = intake.prep_summary;
          } catch {
            /* no intake yet */
          }
        }
      }
      setPrepSummaries(summaries);
    } catch {
      /* API may require auth */
    } finally {
      setLoading(false);
    }
  }, [selectedDoctorId, selectedDate]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  async function handleCheckIn(appointmentId: number) {
    await updateAppointment(appointmentId, { status: "checked_in" });
    loadData();
  }

  async function handleResolveEscalation(id: number) {
    await resolveEscalation(id);
    loadData();
  }

  const urgencyColor: Record<string, string> = {
    low: "bg-slate-100 text-slate-700",
    medium: "bg-amber-100 text-amber-800",
    high: "bg-orange-100 text-orange-800",
    emergency: "bg-red-100 text-red-800",
  };

  return (
    <div className="min-h-screen bg-slate-50">
      <header className="border-b border-slate-200 bg-white">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
          <div>
            <Link href="/" className="text-sm text-blue-600 hover:underline">
              ← Home
            </Link>
            <h1 className="text-lg font-semibold">Doctor Dashboard</h1>
            {user && <p className="text-sm text-slate-500">{user.full_name}</p>}
          </div>
          <div className="flex items-center gap-4">
            <Link href="/login" className="text-sm text-blue-600 hover:underline">
              Login
            </Link>
            <button
              onClick={() => {
                logout();
                window.location.href = "/login";
              }}
              className="text-sm text-slate-500 hover:text-slate-700"
            >
              Logout
            </button>
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-6xl px-6 py-8">
        <div className="mb-6 flex flex-wrap items-center gap-4">
          <div>
            <label className="text-sm font-medium text-slate-700">Doctor</label>
            <select
              value={selectedDoctorId}
              onChange={(e) => setSelectedDoctorId(Number(e.target.value))}
              className="ml-2 rounded-lg border border-slate-300 px-3 py-2"
            >
              {doctors.map((d) => (
                <option key={d.id} value={d.id}>
                  Dr. {d.first_name} {d.last_name} — {d.specialty}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="text-sm font-medium text-slate-700">Date</label>
            <input
              type="date"
              value={selectedDate}
              onChange={(e) => setSelectedDate(e.target.value)}
              className="ml-2 rounded-lg border border-slate-300 px-3 py-2"
            />
          </div>
        </div>

        <div className="grid gap-6 lg:grid-cols-3">
          <div className="lg:col-span-2">
            <h2 className="mb-4 text-lg font-semibold">Today&apos;s Schedule</h2>
            {loading ? (
              <p className="text-slate-500">Loading schedule...</p>
            ) : appointments.length === 0 ? (
              <div className="rounded-xl border border-slate-200 bg-white p-8 text-center text-slate-500">
                No appointments scheduled for this date.
              </div>
            ) : (
              <div className="space-y-4">
                {appointments.map((apt) => (
                  <div
                    key={apt.id}
                    className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm"
                  >
                    <div className="flex items-start justify-between">
                      <div>
                        <p className="font-semibold">
                          {new Date(apt.scheduled_at).toLocaleTimeString([], {
                            hour: "2-digit",
                            minute: "2-digit",
                          })}{" "}
                          — {apt.patient_name}
                        </p>
                        <p className="text-sm text-slate-600">
                          {apt.reason_for_visit || "No reason specified"}
                        </p>
                        <span
                          className={`mt-2 inline-block rounded-full px-2.5 py-0.5 text-xs font-medium ${
                            apt.status === "checked_in"
                              ? "bg-green-100 text-green-800"
                              : apt.status === "scheduled"
                                ? "bg-blue-100 text-blue-800"
                                : "bg-slate-100 text-slate-700"
                          }`}
                        >
                          {apt.status}
                        </span>
                        {!apt.has_intake && (
                          <span className="ml-2 inline-block rounded-full bg-amber-100 px-2.5 py-0.5 text-xs font-medium text-amber-800">
                            Intake pending
                          </span>
                        )}
                      </div>
                      {apt.status === "scheduled" && (
                        <button
                          onClick={() => handleCheckIn(apt.id)}
                          className="rounded-lg bg-teal-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-teal-700"
                        >
                          Check In
                        </button>
                      )}
                    </div>
                    {prepSummaries[apt.id] && (
                      <div className="mt-4 rounded-lg bg-slate-50 p-4">
                        <h4 className="text-sm font-medium text-slate-700">Prep Summary</h4>
                        <pre className="mt-2 whitespace-pre-wrap text-sm text-slate-600">
                          {prepSummaries[apt.id]}
                        </pre>
                      </div>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>

          <div>
            <h2 className="mb-4 text-lg font-semibold">Escalation Inbox</h2>
            {escalations.length === 0 ? (
              <div className="rounded-xl border border-slate-200 bg-white p-6 text-center text-sm text-slate-500">
                No pending escalations
              </div>
            ) : (
              <div className="space-y-3">
                {escalations.map((esc) => (
                  <div
                    key={esc.id}
                    className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm"
                  >
                    <div className="flex items-center justify-between">
                      <span
                        className={`rounded-full px-2 py-0.5 text-xs font-medium ${urgencyColor[esc.urgency] || urgencyColor.medium}`}
                      >
                        {esc.urgency}
                      </span>
                      <button
                        onClick={() => handleResolveEscalation(esc.id)}
                        className="text-xs text-teal-600 hover:underline"
                      >
                        Resolve
                      </button>
                    </div>
                    <p className="mt-2 text-sm text-slate-700">{esc.reason}</p>
                    {esc.patient_name && (
                      <p className="mt-1 text-xs text-slate-500">Patient: {esc.patient_name}</p>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}
