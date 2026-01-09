'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import api from '@/lib/api';

type Field = {
  label: string;
  type: 'text' | 'email' | 'number' | 'textarea' | 'select' | 'radio' | 'checkbox';
  options: string;
  required: boolean;
};

type FieldKey = keyof Field;

export default function CreateForm() {
  const router = useRouter();

  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [fields, setFields] = useState<Field[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  /* -------------------- Field Handlers -------------------- */

  const addField = () => {
    setFields((prev) => [
      ...prev,
      { label: '', type: 'text', options: '', required: false },
    ]);
  };

  const updateField = (
    index: number,
    key: FieldKey,
    value: string | boolean
  ) => {
    const updated = [...fields];
    updated[index][key] = value as never;
    setFields(updated);
  };

  const removeField = (index: number) => {
    setFields((prev) => prev.filter((_, i) => i !== index));
  };

  /* -------------------- Submit -------------------- */

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!title.trim()) {
      setError('Form title is required');
      return;
    }

    const payload = {
      title,
      description,
      fields: fields.map((f) => ({
        ...f,
        options: f.options
          ? f.options.split(',').map((opt) => opt.trim())
          : [],
      })),
    };

    try {
      setLoading(true);
      await api.post('/forms', payload);
      alert('Form created successfully');
      router.push('/');
    } catch (err) {
      console.error(err);
      setError('Failed to create form');
    } finally {
      setLoading(false);
    }
  };

  /* -------------------- UI -------------------- */

  return (
    <div className="min-h-screen bg-gradient-to-br from-emerald-50 via-teal-50 to-green-50 py-8 px-4">
      <div className="max-w-4xl mx-auto">
        {/* Back */}
        <button
          onClick={() => router.push('/')}
          className="mb-6 text-emerald-600 font-medium hover:underline"
        >
          ← Back to Home
        </button>

        {/* Header */}
        <div className="text-center mb-10">
          <h1 className="text-4xl font-bold text-emerald-600 mb-2">
            Create New Form
          </h1>
          <p className="text-slate-600">
            Build a form — no authentication required
          </p>
        </div>

        {/* Error */}
        {error && (
          <div className="mb-6 bg-red-100 border border-red-300 text-red-700 p-4 rounded-lg">
            {error}
          </div>
        )}

        {/* Form */}
        <form
          onSubmit={handleSubmit}
          className="bg-white rounded-2xl shadow-lg p-6 space-y-6"
        >
          {/* Title */}
          <input
            type="text"
            placeholder="Form Title *"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            className="w-full px-4 py-3 border rounded-lg"
          />

          {/* Description */}
          <textarea
            placeholder="Description"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            rows={3}
            className="w-full px-4 py-3 border rounded-lg"
          />

          {/* Fields */}
          <div className="space-y-4">
            <div className="flex justify-between items-center">
              <h2 className="text-xl font-bold">Fields</h2>
              <span className="text-sm text-slate-500">
                {fields.length} fields
              </span>
            </div>

            {fields.map((field, index) => (
              <div
                key={index}
                className="border rounded-xl p-4 space-y-3 bg-slate-50"
              >
                <div className="flex gap-3">
                  <input
                    type="text"
                    placeholder="Field Label"
                    value={field.label}
                    onChange={(e) =>
                      updateField(index, 'label', e.target.value)
                    }
                    className="flex-1 px-3 py-2 border rounded"
                  />

                  <select
                    value={field.type}
                    onChange={(e) =>
                      updateField(
                        index,
                        'type',
                        e.target.value as Field['type']
                      )
                    }
                    className="px-3 py-2 border rounded"
                  >
                    <option value="text">Text</option>
                    <option value="email">Email</option>
                    <option value="number">Number</option>
                    <option value="textarea">Textarea</option>
                    <option value="select">Select</option>
                    <option value="radio">Radio</option>
                    <option value="checkbox">Checkbox</option>
                  </select>

                  <button
                    type="button"
                    onClick={() => removeField(index)}
                    className="px-3 py-2 bg-red-500 text-white rounded"
                  >
                    Remove
                  </button>
                </div>

                {(field.type === 'select' || field.type === 'radio') && (
                  <input
                    type="text"
                    placeholder="Options (comma separated)"
                    value={field.options}
                    onChange={(e) =>
                      updateField(index, 'options', e.target.value)
                    }
                    className="w-full px-3 py-2 border rounded"
                  />
                )}

                <label className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={field.required}
                    onChange={(e) =>
                      updateField(index, 'required', e.target.checked)
                    }
                  />
                  Required
                </label>
              </div>
            ))}

            <button
              type="button"
              onClick={addField}
              className="w-full border-2 border-dashed border-emerald-400 py-3 rounded-xl text-emerald-600 font-semibold"
            >
              + Add Field
            </button>
          </div>

          {/* Submit */}
          <button
            type="submit"
            disabled={loading}
            className="w-full py-4 bg-emerald-600 text-white font-bold rounded-xl disabled:opacity-50"
          >
            {loading ? 'Creating...' : 'Create Form'}
          </button>
        </form>
      </div>
    </div>
  );
}
