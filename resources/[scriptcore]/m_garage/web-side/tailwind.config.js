/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './index.html',
    './src/**/*.{html,tsx}'
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Montserrat']
      },
      colors: {
        primary: '#2981FF'
      },
      background: {
      },
      backgroundImage: {
        'back': 'url("/images/background.webp")',
        'primary-gradient': 'linear-gradient(135deg, #2981FF 0%, #0030ff 100%)'
      },
      boxShadow: {
        'primary': '0 0 .875rem 0 #2981FF'
      }
    },
  },
  plugins: [
    require('tailwindcss-animated')
  ],
}

