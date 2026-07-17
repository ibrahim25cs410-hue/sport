/** @type {import('tailwindcss').Config} */
export default {
  darkMode: 'class',
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        pitch: {
          50: '#f2f8f3',
          100: '#e0efe3',
          200: '#c2dec8',
          300: '#94c49f',
          400: '#5fa36f',
          500: '#3d8550',
          600: '#2d6a3e',
          700: '#255533',
          800: '#1f442b',
          900: '#1a3824',
          950: '#0c1f13',
        },
      },
      fontFamily: {
        display: ['"IBM Plex Sans Arabic"', 'Tahoma', 'sans-serif'],
        body: ['"IBM Plex Sans Arabic"', 'Tahoma', 'sans-serif'],
      },
      boxShadow: {
        panel: '0 1px 0 rgba(12,31,19,0.06), 0 12px 40px rgba(12,31,19,0.08)',
        'panel-dark': '0 1px 0 rgba(255,255,255,0.04), 0 12px 40px rgba(0,0,0,0.35)',
      },
    },
  },
  plugins: [],
};
