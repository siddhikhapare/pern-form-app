'use client';

import { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import api from '@/lib/api';

type FormItem = {
  id: number;
  title: string;
  description?: string;
  created_at?: string;
  response_count?: string;
};

export default function HomePage() {
  const [recentForms, setRecentForms] = useState<FormItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string>('');

  const fetchRecentForms = useCallback(async () => {
    try {
      setLoading(true);
      const response = await api.get('/forms?limit=6');

      if (response.data?.success && response.data.forms) {
        setRecentForms(response.data.forms);
      }
    } catch (err) {
      console.error('Failed to fetch forms:', err);
      setError('Failed to load forms');

      // fallback demo data
      setRecentForms([
        { id: 1, title: 'Customer Feedback Survey', description: 'Share your experience' },
        { id: 2, title: 'Event Registration Form', description: 'Sign up for upcoming events' },
        { id: 3, title: 'Contact Us Form', description: 'Get in touch with our team' },
      ]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchRecentForms();
  }, [fetchRecentForms]);

  return (
    <div className="min-h-screen relative overflow-hidden">
      {/* Background */}
      <div className="absolute inset-0 z-0 bg-gradient-to-br from-emerald-900 via-teal-800 to-green-900" />

      {/* Content */}
      <div className="relative z-10 min-h-screen flex flex-col">
        {/* Header */}
        <header className="w-full py-6 px-6">
          <div className="max-w-7xl mx-auto flex items-center justify-between">
            <h2 className="text-xl font-bold text-white">FormBuilder</h2>

            <Link
              href="/create-form"
              className="px-5 py-2.5 bg-gradient-to-r from-emerald-500 to-teal-500 text-white rounded-lg font-semibold"
            >
              Create Form
            </Link>
          </div>
        </header>

        {/* Main */}
        <main className="flex-1 px-6 py-12 max-w-7xl mx-auto w-full">
          <div className="text-center mb-12">
            <h1 className="text-5xl font-bold text-white mb-4">
              Build Beautiful Forms
            </h1>
            <p className="text-emerald-100 text-lg">
              Form builder with simple CRUD operations
            </p>
          </div>

          {/* Recent Forms */}
          <div className="bg-white rounded-2xl shadow-xl p-8">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-bold text-emerald-600">
                Recent Forms
              </h2>
              <button
                onClick={fetchRecentForms}
                disabled={loading}
                className="text-emerald-600 font-semibold"
              >
                Refresh
              </button>
            </div>

            {error && (
              <div className="mb-4 text-yellow-700 bg-yellow-100 p-3 rounded-lg">
                {error}
              </div>
            )}

            {loading ? (
              <div className="flex justify-center py-10">
                <div className="animate-spin h-10 w-10 border-4 border-emerald-500 border-t-transparent rounded-full" />
              </div>
            ) : recentForms.length > 0 ? (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
                {recentForms.map((form) => (
                  <Link
                    key={form.id}
                    href={`/viewforms/${form.id}`}
                    className="border rounded-xl p-5 hover:shadow-lg transition"
                  >
                    <h3 className="text-lg font-bold text-slate-800 mb-2">
                      {form.title}
                    </h3>
                    {form.description && (
                      <p className="text-sm text-slate-600">
                        {form.description}
                      </p>
                    )}
                    <div className="mt-4 text-emerald-600 font-semibold text-sm">
                      View Form →
                    </div>
                  </Link>
                ))}
              </div>
            ) : (
              <div className="text-center py-12">
                <p className="text-slate-500 mb-4">No forms available</p>
                <Link
                  href="/create-form"
                  className="inline-block px-6 py-3 bg-emerald-600 text-white rounded-lg"
                >
                  Create First Form
                </Link>
              </div>
            )}
          </div>
        </main>
      </div>
    </div>
  );
}
