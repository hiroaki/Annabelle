// const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}',
    './app/presenters/**/*.rb',
  ],
  theme: {
    extend: {
      fontFamily: {
//         sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
      scrollbarGutter: {
        stable: 'stable',
      },
    },
  },
}
