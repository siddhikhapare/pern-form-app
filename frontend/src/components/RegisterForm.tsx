// 'use client';
// import { useState } from 'react';
// import { useRouter } from 'next/navigation';
// import api from '@/lib/api';

// export default function RegisterForm() {
//   const router = useRouter();
//   const [formData, setFormData] = useState({
//     name: '',
//     email: '',
//     password: '',
//     confirmPassword: ''
//   });
//   const [error, setError] = useState('');
//   const [loading, setLoading] = useState(false);

//   const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
//     setFormData({
//       ...formData,
//       [e.target.name]: e.target.value
//     });
//   };

//   const handleSubmit = async (e: React.FormEvent) => {
//     e.preventDefault();
//     setError('');

//     // Validation
//     if (!formData.name || !formData.email || !formData.password) {
//       setError('All fields are required');
//       return;
//     }

//     if (formData.password !== formData.confirmPassword) {
//       setError('Passwords do not match');
//       return;
//     }

//     if (formData.password.length < 6) {
//       setError('Password must be at least 6 characters');
//       return;
//     }

//     setLoading(true);

//     try {
//       const response = await api.post('/auth/register', {
//         name: formData.name,
//         email: formData.email,
//         password: formData.password
//       });

//       if (response.data.success) {
//         // Redirect to login page after successful registration
//         router.push('/login?registered=true');
//       }
//     } catch (err) {
//         if (err instanceof Error) {
//             setError(err.message);
//         } else if (typeof err === 'object' && err !== null && 'response' in err) {
//             const axiosErr = err as { response?: { data?: { message?: string } } };
//             setError(axiosErr.response?.data?.message || 'Registration failed. Please try again.');
//         } else {
//             setError('Registration failed. Please try again.');
//         }
//       //setError(err.response?.data?.message || 'Registration failed. Please try again.');
//     } finally {
//       setLoading(false);
//     }
//   };

//   return (
//     <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
//       {error && (
//         <div className="rounded-md bg-red-50 p-4">
//           <p className="text-sm text-red-800">{error}</p>
//         </div>
//       )}
      
//       <div className="rounded-md shadow-sm -space-y-px">
//         <div>
//           <label htmlFor="name" className="sr-only">
//             Full Name
//           </label>
//           <input
//             id="name"
//             name="name"
//             type="text"
//             required
//             className="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-t-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm"
//             placeholder="Full Name"
//             value={formData.name}
//             onChange={handleChange}
//           />
//         </div>
//         <div>
//           <label htmlFor="email" className="sr-only">
//             Email address
//           </label>
//           <input
//             id="email"
//             name="email"
//             type="email"
//             autoComplete="email"
//             required
//             className="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm"
//             placeholder="Email address"
//             value={formData.email}
//             onChange={handleChange}
//           />
//         </div>
//         <div>
//           <label htmlFor="password" className="sr-only">
//             Password
//           </label>
//           <input
//             id="password"
//             name="password"
//             type="password"
//             autoComplete="new-password"
//             required
//             className="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm"
//             placeholder="Password"
//             value={formData.password}
//             onChange={handleChange}
//           />
//         </div>
//         <div>
//           <label htmlFor="confirmPassword" className="sr-only">
//             Confirm Password
//           </label>
//           <input
//             id="confirmPassword"
//             name="confirmPassword"
//             type="password"
//             autoComplete="new-password"
//             required
//             className="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-b-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm"
//             placeholder="Confirm Password"
//             value={formData.confirmPassword}
//             onChange={handleChange}
//           />
//         </div>
//       </div>

//       <div>
//         <button
//           type="submit"
//           disabled={loading}
//           className="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
//         >
//           {loading ? 'Creating account...' : 'Sign up'}
//         </button>
//       </div>
//     </form>
//   );
// }