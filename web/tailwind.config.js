/** @type {import('tailwindcss').Config} */
export default {
  darkMode: 'class',
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#E8F5E9',
          100: '#C8E6C9',
          200: '#A5D6A7',
          300: '#81C784',
          400: '#66BB6A',
          500: '#2E7D32',
          600: '#1B5E20',
          700: '#145214',
          800: '#0D3B10',
          900: '#062408',
        },
        accent: {
          DEFAULT: '#FFC107',
          dark: '#FFA000',
        },
        surface: {
          DEFAULT: 'rgb(var(--color-surface) / <alpha-value>)',
          variant: 'rgb(var(--color-surface-variant) / <alpha-value>)',
        },
        background: 'rgb(var(--color-background) / <alpha-value>)',
      },
      fontFamily: {
        cairo: ['Cairo', 'sans-serif'],
      },
      boxShadow: {
        card: '0 4px 20px rgba(27, 94, 32, 0.08)',
        float: '0 8px 32px rgba(27, 94, 32, 0.15)',
      },
      animation: {
        'fade-in': 'fadeIn 0.4s ease-out',
        'slide-up': 'slideUp 0.4s ease-out',
        'pulse-soft': 'pulseSoft 2s infinite',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { opacity: '0', transform: 'translateY(20px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        pulseSoft: {
          '0%, 100%': { opacity: '1' },
          '50%': { opacity: '0.7' },
        },
      },
    },
  },
  plugins: [],
};
