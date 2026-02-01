/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{js,jsx,ts,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#D81B60',
          dark: '#AD1457',
          light: '#FF5C8D',
        },
      },
    },
  },
  plugins: [],
}
