// 'use client';
// import { useState } from 'react';
// import { useRouter } from 'next/navigation';
// import api from '@/lib/api';

// export default function LoginForm() {
//   const router = useRouter();
//   const [formData, setFormData] = useState({
//     email: '',
//     password: ''
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

//     if (!formData.email || !formData.password) {
//       setError('Email and password are required');
//       return;
//     }

//     setLoading(true);

//     try {
//       const response = await api.post('/auth/login', {
//         email: formData.email,
//         password: formData.password
//       });

//       if (response.data.success) {
//         // Store token in localStorage
//         localStorage.setItem('token', response.data.token);
//         localStorage.setItem('user', JSON.stringify(response.data.user));
        
//         // Redirect to forms page
//         router.push('/forms');
//       }
//     } catch (err) {
//         if (err instanceof Error) {
//             setError(err.message);
//         } else if (typeof err === 'object' && err !== null && 'response' in err) {
//             const axiosErr = err as { response?: { data?: { message?: string } } };
//             setError(axiosErr.response?.data?.message || 'Login failed. Please check your credentials.');
//         } else {
//             setError('Login failed. Please check your credentials.');
//         }
//       //setError(err.response?.data?.message || 'Login failed. Please check your credentials.');
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
//           <label htmlFor="email" className="sr-only">
//             Email address
//           </label>
//           <input
//             id="email"
//             name="email"
//             type="email"
//             autoComplete="email"
//             required
//             className="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-t-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm"
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
//             autoComplete="current-password"
//             required
//             className="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-b-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm"
//             placeholder="Password"
//             value={formData.password}
//             onChange={handleChange}
//           />
//         </div>
//       </div>

//       <div className="flex items-center justify-between">
//         <div className="flex items-center">
//           <input
//             id="remember-me"
//             name="remember-me"
//             type="checkbox"
//             className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
//           />
//           <label htmlFor="remember-me" className="ml-2 block text-sm text-gray-900">
//             Remember me
//           </label>
//         </div>

//         <div className="text-sm">
//           <a href="#" className="font-medium text-blue-600 hover:text-blue-500">
//             Forgot your password?
//           </a>
//         </div>
//       </div>

//       <div>
//         <button
//           type="submit"
//           disabled={loading}
//           className="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
//         >
//           {loading ? 'Signing in...' : 'Sign in'}
//         </button>
//       </div>
//     </form>
//   );
// }