/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,jsx}"],
  theme: {
    extend: {
      colors: {
        ink: "#1A1A1A",
        paper: "#F6F5F1",
        teal: {
          DEFAULT: "#0F3D3E",
          50: "#E7EEED",
          100: "#CFE0DE",
          600: "#16585A",
          700: "#0F3D3E",
          900: "#082323",
        },
        sage: {
          DEFAULT: "#6B8E8E",
          100: "#E3EAEA",
        },
        terracotta: {
          DEFAULT: "#C9622D",
          50: "#FBEEE6",
          100: "#F5DCC9",
        },
        line: "#E8E4DC",
        risk: {
          1: "#4F8A5B",
          2: "#8BAA4E",
          3: "#D4A12C",
          4: "#D9763B",
          5: "#C1432E",
        },
      },
      fontFamily: {
        display: ["Amiri", "Georgia", "serif"],
        body: ["IBM Plex Sans Arabic", "Tahoma", "Arial", "sans-serif"],
        mono: ["IBM Plex Mono", "monospace"],
      },
      borderRadius: {
        sm: "4px",
        DEFAULT: "8px",
        lg: "12px",
      },
    },
  },
  plugins: [],
};
