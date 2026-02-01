# Roblox Developer Portfolio

A modern portfolio website built with Vite, React, TypeScript, and Tailwind CSS to showcase Roblox development projects.

## Technologies

- **Vite** - Fast build tool and dev server
- **React 18** - UI library
- **TypeScript** - Type-safe JavaScript
- **Tailwind CSS** - Utility-first CSS framework  
- **shadcn/ui** - Re-usable component system

## Getting Started

### Install Dependencies

```bash
npm install
```

### Development

```bash
npm run dev
```

Opens the dev server at `http://localhost:5173`

### Build

```bash
npm run build
```

Builds for production to the `dist/` folder.

### Preview Build

```bash
npm run preview
```

## Project Structure

```
portfolio/
├── src/
│   ├── components/    # React components
│   │   └── ui/        # shadcn/ui components
│   ├── lib/           # Utility functions
│   ├── App.tsx        # Main app component
│   ├── main.tsx       # Entry point
│   └── index.css      # Global styles
├── public/            # Static assets
└── dist/              # Build output
```

## Roblox Projects Featured

Coming soon! This portfolio will showcase:
1. A crafting system
2. Modular framework including datastore and bus system for clean server-client data and state sync
3. Basic declarative UI scripting using React
4. Plot assigner
5. Basic throwing mechanic
import reactDom from 'eslint-plugin-react-dom'

export default defineConfig([
  globalIgnores(['dist']),
  {
    files: ['**/*.{ts,tsx}'],
    extends: [
      // Other configs...
      // Enable lint rules for React
      reactX.configs['recommended-typescript'],
      // Enable lint rules for React DOM
      reactDom.configs.recommended,
    ],
    languageOptions: {
      parserOptions: {
        project: ['./tsconfig.node.json', './tsconfig.app.json'],
        tsconfigRootDir: import.meta.dirname,
      },
      // other options...
    },
  },
])
```
