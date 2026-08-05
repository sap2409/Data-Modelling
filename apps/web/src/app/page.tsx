import Link from "next/link";

export default function Home() {
  return (
    <div className="min-h-screen">
      <header className="border-b border-slate-200 bg-white">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-teal-600 text-lg font-bold text-white">
              C
            </div>
            <div>
              <h1 className="text-lg font-semibold">CityCare General Hospital</h1>
              <p className="text-sm text-slate-500">AI Receptionist Platform</p>
            </div>
          </div>
          <Link
            href="/login"
            className="rounded-lg bg-teal-600 px-4 py-2 text-sm font-medium text-white hover:bg-teal-700"
          >
            Staff Login
          </Link>
        </div>
      </header>

      <main className="mx-auto max-w-6xl px-6 py-16">
        <div className="text-center">
          <h2 className="text-4xl font-bold tracking-tight text-slate-900">
            Your AI Receptionist, Always Ready
          </h2>
          <p className="mx-auto mt-4 max-w-2xl text-lg text-slate-600">
            Book appointments, get hospital information, and connect with the right
            department — powered by AI. Doctors get real-time schedules and patient prep
            summaries.
          </p>
        </div>

        <div className="mt-16 grid gap-6 md:grid-cols-3">
          <Link
            href="/chat"
            className="group rounded-2xl border border-slate-200 bg-white p-8 shadow-sm transition hover:border-teal-300 hover:shadow-md"
          >
            <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-xl bg-teal-100 text-2xl">
              💬
            </div>
            <h3 className="text-xl font-semibold group-hover:text-teal-700">Patient Chat</h3>
            <p className="mt-2 text-slate-600">
              Talk to our AI receptionist to book appointments, ask questions, and get
              help 24/7.
            </p>
          </Link>

          <Link
            href="/doctor"
            className="group rounded-2xl border border-slate-200 bg-white p-8 shadow-sm transition hover:border-blue-300 hover:shadow-md"
          >
            <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-xl bg-blue-100 text-2xl">
              🩺
            </div>
            <h3 className="text-xl font-semibold group-hover:text-blue-700">Doctor Dashboard</h3>
            <p className="mt-2 text-slate-600">
              View today&apos;s schedule, patient prep summaries, and escalation inbox.
            </p>
          </Link>

          <Link
            href="/intake"
            className="group rounded-2xl border border-slate-200 bg-white p-8 shadow-sm transition hover:border-purple-300 hover:shadow-md"
          >
            <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-xl bg-purple-100 text-2xl">
              📋
            </div>
            <h3 className="text-xl font-semibold group-hover:text-purple-700">Patient Intake</h3>
            <p className="mt-2 text-slate-600">
              Complete your pre-visit intake form so your doctor is prepared.
            </p>
          </Link>
        </div>

        <div className="mt-16 rounded-2xl border border-amber-200 bg-amber-50 p-6">
          <h3 className="font-semibold text-amber-900">Demo Credentials</h3>
          <div className="mt-3 grid gap-2 text-sm text-amber-800 md:grid-cols-2">
            <p>Doctor: dr.smith@citycare.com / doctor123</p>
            <p>Receptionist: reception@citycare.com / reception123</p>
            <p>Patient: alice@email.com / patient123</p>
            <p>Admin: admin@citycare.com / admin123</p>
          </div>
        </div>
      </main>
    </div>
  );
}
