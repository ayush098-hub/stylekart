/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{js,jsx,ts,tsx}"],
  theme: {
    extend: {
      colors: {
        primary: "#FF3F6C",
        dark: "#1a1a1a",
      },
    },
  },
  plugins: [require("@tailwindcss/forms")],
};
