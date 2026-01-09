'use client';

import { useState, useEffect, useCallback } from 'react';
import { useParams, useRouter } from 'next/navigation';
import api from '@/lib/api';

type FormField = {
  id?: string;
  label: string;
  type: 'text' | 'email' | 'number' | 'textarea' | 'select' | 'radio' | 'checkbox';
  options: string[];
  required: boolean;
};

type FormType = {
  title: string;
  description?: string;
  fields: FormField[];
};

type ResponseData = {
  [key: string]: string | boolean;
};

export default function ViewForm() {
  const { id } = useParams();
  const router = useRouter();

  const [form, setForm] = useState<FormType | null>(null);
  const [responses, setResponses] = useState<ResponseData>({});
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');

  /* ---------------- Fetch Form ---------------- */

  const fetchForm = useCallback(async () => {
    try {
      setLoading(true);
      const res = await api.get(`/forms/${id}`);
      setForm(res.data.form);
    } catch (err) {
      console.error(err);
      setError('Failed to load form');
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => {
    if (id) fetchForm();
  }, [id, fetchForm]);

  /* ---------------- Handlers ---------------- */

  const handleChange = (label: string, value: string | boolean) => {
    setResponses((prev) => ({ ...prev, [label]: value }));
  };

  const handleSubmit = async () => {
    setSubmitting(true);
    setError('');

    try {
      await api.post(`/forms/${id}/responses`, { responses });
      alert('Response submitted successfully');
      router.push('/');
    } catch (err) {
      console.error(err);
      setError('Failed to submit response');
    } finally {
      setSubmitting(false);
    }
  };

  /* ---------------- States ---------------- */

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin h-12 w-12 border-4 border-emerald-500 border-t-transparent rounded-full" />
      </div>
    );
  }

  if (!form || error) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="bg-white p-8 rounded-xl shadow text-center">
          <h2 className="text-xl font-bold mb-2">Form Not Found</h2>
          <p className="text-slate-600 mb-4">{error}</p>
          <button
            onClick={() => router.push('/')}
            className="px-6 py-3 bg-emerald-600 text-white rounded-lg"
          >
            Go Home
          </button>
        </div>
      </div>
    );
  }

  /* ---------------- UI ---------------- */

  return (
    <div className="min-h-screen bg-gradient-to-br from-emerald-50 via-teal-50 to-green-50 px-4 py-8">
      <div className="max-w-3xl mx-auto">
        <button
          onClick={() => router.push('/')}
          className="mb-4 text-emerald-600 font-medium"
        >
          ← Back to Home
        </button>

        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold text-emerald-600">{form.title}</h1>
          {form.description && (
            <p className="mt-2 text-slate-600">{form.description}</p>
          )}
        </div>

        <div className="bg-white rounded-2xl shadow p-6 space-y-6">
          {form.fields.map((field) => (
            <div key={field.id || field.label}>
              <label className="block font-semibold mb-2">
                {field.label}
                {field.required && <span className="text-red-500">*</span>}
              </label>

              {field.type === 'textarea' ? (
                <textarea
                  rows={4}
                  value={(responses[field.label] as string) || ''}
                  onChange={(e) =>
                    handleChange(field.label, e.target.value)
                  }
                  className="w-full border px-4 py-2 rounded"
                />
              ) : field.type === 'select' ? (
                <select
                  value={(responses[field.label] as string) || ''}
                  onChange={(e) =>
                    handleChange(field.label, e.target.value)
                  }
                  className="w-full border px-4 py-2 rounded"
                >
                  <option value="">Select option</option>
                  {field.options.map((opt, i) => (
                    <option key={i}>{opt}</option>
                  ))}
                </select>
              ) : field.type === 'radio' ? (
                <div className="space-y-2">
                  {field.options.map((opt) => (
                    <label key={opt} className="flex items-center gap-2">
                      <input
                        type="radio"
                        name={field.label}
                        value={opt}
                        checked={responses[field.label] === opt}
                        onChange={(e) =>
                          handleChange(field.label, e.target.value)
                        }
                      />
                      {opt}
                    </label>
                  ))}
                </div>
              ) : field.type === 'checkbox' ? (
                <input
                  type="checkbox"
                  checked={(responses[field.label] as boolean) || false}
                  onChange={(e) =>
                    handleChange(field.label, e.target.checked)
                  }
                />
              ) : (
                <input
                  type={field.type}
                  value={(responses[field.label] as string) || ''}
                  onChange={(e) =>
                    handleChange(field.label, e.target.value)
                  }
                  className="w-full border px-4 py-2 rounded"
                />
              )}
            </div>
          ))}

          <button
            onClick={handleSubmit}
            disabled={submitting}
            className="w-full py-4 bg-emerald-600 text-white rounded-xl font-bold disabled:opacity-50"
          >
            {submitting ? 'Submitting...' : 'Submit Response'}
          </button>
        </div>
      </div>
    </div>
  );
}
