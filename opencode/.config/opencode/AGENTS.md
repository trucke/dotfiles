At the start of each session, read:
1. Any `**/README.md` docs across the project
2. Any `**/README.*.md` docs across the project

## General

- Use spaces for indentation.
- Default to 4 spaces.
- Focus on the most efficient but secure solutions.
- Never use apologies.
- Don't add comments all over the place. Only comment where it adds value.
- Don't use git commit or git push if not otherwise instructed by the user.
- Use the todo tool to break down your task and progress.
- Focus on simplicity, maintainability, testability, security, readability, performance.
- Only modify sections of the code related to the task at hand.
- Avoid modifying unrelated pieces of code.
- Accomplish goals with minimal code changes.

## Code Quality Guidelines

- Always verify information before presenting it. Do not make assumptions or speculate without clear evidence.
- Make changes file by file and give me a chance to spot mistakes.
- Avoid giving feedback about understanding in comments or documentation.
- Don't suggest whitespace changes.
- Don't summarize changes made.
- Don't invent changes other than what's explicitly requested.
- Don't remove unrelated code or functionalities. Pay attention to preserving existing structures.
- Don't suggest updates or changes to files when there are no actual modifications needed.
- Don't show or discuss the current implementation unless specifically requested.

## JavaScript/TypeScript

- Always prefer arrow functions.
- Prefer functional coding style.
- Prefer interfaces over types for object definitions
- Avoid using `any`, prefer `unknown` for unknown types
- Use strict Typescript configuration
- Keep type definitions close to where they're used
- Leverage Typescript's built-in utility types
- Use generics for reusable type patterns
- Export types and interfaces from dedicated type files when shared
- Co-locate component props with their components
- Use explicit return types for public functions
- Prefer async/await over Promises
- Implement proper null checking
- Avoid type assertions unless necessary
- Use Result types for operations that can fail
- Implement proper error boundaries
- Handle Promise rejections properly
- Use early returns to avoid nested conditions and improve readability.
- JSDoc Comments: Use JSDoc comments for JavaScript and modern ES6 syntax.

## Astro

- Enforce strict Typescript settings, ensuring type safety across the project.
- Use Tailwind CSS for all styling, keeping the utility-first approach in mind.
- Ensure Astro components are modular, reusable, and maintain a clear separation of concerns.
- Ensure proper semantic HTML structure in Astro components.
- Implement ARIA attributes where necessary.
- Ensure keyboard navigation support for interactive elements.
- Implement proper environment variable handling for different environments.
- Create .astro files for Astro components.
- Implement proper component composition and reusability.
- Use Astro's component props for data passing.
- Leverage Astro's built-in components when appropriate.
- Use Markdown (.md) or MDX (.mdx) files for content-heavy pages.
- Leverage Astro's built-in support for frontmatter in Markdown files.
- Implement content collections for organized content management.
- Implement proper error handling for data fetching operations.
- Implement proper lazy loading for images and other assets.
- Utilize Astro's built-in asset optimization features.
- Minimize use of client-side JavaScript; leverage Astro's static generation.
- Use the client:* directives judiciously for partial hydration:
  - client:load for immediately needed interactivity
  - client:idle for non-critical interactivity
  - client:visible for components that should hydrate when visible

## Tailwind CSS (v4) Best Practices

- Prefer `const` over `let` when variables won't be reassigned
- Keep accessibility in mind
- Use mobile-first approach
- Handle different screen sizes properly
- Use proper responsive design utilities
- Group related utilities with @apply when needed
- Configure custom colors properly
- Use opacity utilities effectively
- Use semantic color naming
- Configure custom fonts properly
- Use container queries when needed
- Use Flexbox and Grid utilities effectively
- Implement dark mode properly
- Use utility classes over custom CSS
- Optimize for production
- Keep styles organized
