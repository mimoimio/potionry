import { Hero } from "./components/Hero";
import { ShowcaseCard } from "./components/ShowcaseCard";
import { Skills } from "./components/Skills";
import { projects } from "./lib/data";
import { Separator } from "./components/ui/separator";
import { Github, Mail, Twitter } from "lucide-react";
import { Button } from "./components/ui/button";

function App() {
  return (
    <div className="min-h-screen bg-background text-foreground font-sans selection:bg-primary/20">
      <Hero />

      <main id="projects" className="py-20 container mx-auto px-4">
        <div className="text-center mb-16 space-y-4">
          <h2 className="text-3xl md:text-5xl font-bold tracking-tight">Featured <span className="text-primary">Projects</span></h2>
          <p className="text-muted-foreground text-lg max-w-2xl mx-auto">
            A collection of my work demonstrating complex systems, UI architecture, and gameplay mechanics.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {projects.map((project, index) => (
            <ShowcaseCard key={project.id} project={project} index={index} />
          ))}
        </div>
      </main>

      <Skills />

      <footer id="contact" className="py-20 border-t bg-background">
        <div className="container mx-auto px-4 flex flex-col items-center text-center space-y-8">
          <div className="space-y-4">
            <h2 className="text-3xl font-bold">Let's Work Together</h2>
            <p className="text-muted-foreground max-w-md mx-auto">
              I'm always open to discussing new projects, creative ideas or opportunities to be part of your visions.
            </p>
          </div>

          <div className="flex gap-4">
            <Button variant="ghost" size="icon" className="rounded-full">
              <Github className="w-5 h-5" />
            </Button>
            <Button variant="ghost" size="icon" className="rounded-full">
              <Twitter className="w-5 h-5" />
            </Button>
            <Button variant="ghost" size="icon" className="rounded-full">
              <Mail className="w-5 h-5" />
            </Button>
          </div>

          <Separator className="w-1/2" />

          <p className="text-sm text-muted-foreground">
            © {new Date().getFullYear()} Roblox Developer Portfolio. Built with React, Vite & Tailwind.
          </p>
        </div>
      </footer>
    </div>
  );
}

export default App;
