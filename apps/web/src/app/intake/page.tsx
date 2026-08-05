"use client";

import { FormEvent, useState } from "react";
import Link from "next/link";
import { submitIntake } from "@/lib/api";

export default function IntakePage() {
  const [appointmentId, setAppointmentId] = useState(1);
  const [symptoms, setSymptoms] = useState("");
  const [medications, setMedications] = useState("");
  const [allergies, setAllergies] = useState("");
  const [notes, setNotes] = useState("");
  const [submitted, setSubmitted] = useState(false);
  const [prepSummary, setPrepSummary] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      const result = await submitIntake(appointmentId, {
        symptoms_summary: symptoms,
        medications,
        allergies,
        additional_notes: notes,
      });
      setPrepSummary(result.prep_summary || "");
      setSubmitted(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to submit intake");
    } finally {
      setLoading(false);
    }
  }

  if (submitted) {
    return (
      <div className="min-h-screen bg-slate-50 px-4 py-16">
        <div className="mx-auto max-w-2xl rounded-2xl border border-green-200 bg-white p-8 shadow-sm">
          <h1 className="text-2xl font-bold text-green-800">Intake Submitted</h1>
          <p className="mt-2 text-slate-600">
            Thank you! Your doctor will review this information before your visit.
          </p>
          {prepSummary && (
            <div className="mt-6 rounded-lg bg-slate-50 p-4">
              <h3 className="font-medium text-slate-700">Prep Summary (for your doctor)</h3>
              <pre className="mt-2 whitespace-pre-wrap text-sm text-slate-600">{prepSummary}</pre>
            </div>
          )}
          <Link href="/" className="mt-6 inline-block text-teal-600 hover:underline">
            ← Back to home
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-50 px-4 py-16">
      <div className="mx-auto max-w-2xl">
        <Link href="/" className="text-sm text-purple-600 hover:underline">
          ← Back to home
        </Link>
        <h1 className="mt-4 text-2xl font-bold">Pre-Visit Intake Form</h1>
        <p className="mt-1 text-slate-600">
          Please complete this form before your appointment so your doctor can prepare.
        </p>

        <form onSubmit={handleSubmit} className="mt-8 space-y-6 rounded-2xl border border-slate-200 bg-white p-8 shadow-sm">
          <div>
            <label className="block text-sm font-medium text-slate-700">Appointment ID</label>
            <input
              type="number"
              value={appointmentId}
              onChange={(e) => setAppointmentId(Number(e.target.value))}
              className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
              min={1}
              required
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-slate-700">
              Symptoms / Reason for Visit
            </label>
            <textarea
              value={symptoms}
              onChange={(e) => setSymptoms(e.target.value)}
              rows={3}
              className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
              placeholder="Describe your symptoms or reason for the visit"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-slate-700">Current Medications</label>
            <textarea
              value={medications}
              onChange={(e) => setMedications(e.target.value)}
              rows={2}
              className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
              placeholder="List any medications you are currently taking"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-slate-700">Allergies</label>
            <textarea
              value={allergies}
              onChange={(e) => setAllergies(e.target.value)}
              rows={2}
              className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
              placeholder="List any known allergies"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-slate-700">Additional Notes</label>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              rows={2}
              className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
              placeholder="Anything else your doctor should know"
            />
          </div>
          {error && <p className="text-sm text-red-600">{error}</p>}
          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-lg bg-purple-600 py-2.5 font-medium text-white hover:bg-purple-700 disabled:opacity-50"
          >
            {loading ? "Submitting..." : "Submit Intake Form"}
          </button>
        </form>
      </div>
    </div>
  );
}
