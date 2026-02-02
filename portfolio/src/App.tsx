import { Hero } from "./components/Hero";
import { Skills } from "./components/Skills";
import { ShowcaseCard } from "./components/ShowcaseCard";
import { projects } from "./lib/data";
import { Separator } from "./components/ui/separator";
import { Button } from "./components/ui/button";

function App() {
  return (
    <div className="min-h-screen bg-background text-foreground font-sans selection:bg-primary/20">
      <Hero />

      <main id="projects" className="py-20 container mx-auto px-4">
        <div className="text-center mb-16 space-y-4">
          <h2 className="text-3xl md:text-5xl font-bold tracking-tight">Featured <span className="text-primary">Projects</span></h2>
          <p className="text-muted-foreground text-lg max-w-2xl mx-auto">
            My previous works consist of modular frameworks, declarative UI scripting, and a bit of gameplay mechanics.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-2 gap-6">
          {projects.map((project, index) => (
            <ShowcaseCard key={project.id} project={project} index={index} />
          ))}
        </div>
      </main>

      <section className="py-20 container mx-auto px-4 bg-muted/30">
        <div className="text-center mb-12 space-y-4">
          <h2 className="text-3xl md:text-5xl font-bold tracking-tight">Published <span className="text-primary">Titles</span></h2>
          <p className="text-muted-foreground text-lg max-w-2xl mx-auto">
            Check out my current Live Projects
          </p>
        </div>

        <div className="max-w-2xl mx-auto">
          <a
            href="https://www.roblox.com/games/100208898672356/THROW-POTIONS-n-GET-RICH"
            target="_blank"
            rel="noopener noreferrer"
            className="block group"
          >
            <div className="border rounded-lg overflow-hidden bg-card hover:shadow-xl transition-all duration-300 hover:-translate-y-1">
              <div className="aspect-video bg-gradient-to-br from-primary/20 to-primary/5 flex items-center justify-center">
                <div className="text-6xl">                            <img
                  src={'projects/thumbnail.png'}
                  alt={'throw potions'}
                  className="w-full h-full object-cover transition-transform duration-300 group-hover:scale-105"
                />
                </div>
              </div>
              <div className="p-6 space-y-3">
                <h3 className="text-2xl font-bold group-hover:text-primary transition-colors">THROW POTIONS n GET RICH</h3>
                <p className="text-muted-foreground">
                  Inspired by Little Alchemy type of game and other similar roblox games like Craft Food where you craft potions
                </p>
                <div className="flex gap-2 flex-wrap">
                  <span className="text-xs px-3 py-1 rounded-full bg-primary/10 text-primary">Casual</span>
                  <span className="text-xs px-3 py-1 rounded-full bg-primary/10 text-primary">Tycoon</span>
                </div>
              </div>
            </div>
          </a>
        </div>
      </section>

      <Skills />

      <footer id="contact" className="py-20 border-t bg-background">
        <div className="container mx-auto px-4 flex flex-col items-center text-center space-y-8">
          <div className="space-y-4">
            <h2 className="text-3xl font-bold">Commission Information</h2>
            <p className="text-muted-foreground max-w-md mx-auto">
              I'm always open to discussing new projects, creative ideas or opportunities to be part of your visions.
            </p>
          </div>

          <div className="flex gap-4 flex-wrap justify-center">
            <Button
              variant="outline"
              className="rounded-full hover:bg-primary/10 hover:text-primary hover:border-primary/50 transition-colors"
              asChild
            >
              <a href="https://discord.com/users/1463515044812820589" target="_blank" rel="noopener noreferrer" className="flex items-center gap-2">
                <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M20.317 4.37a19.791 19.791 0 0 0-4.885-1.515a.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0a12.64 12.64 0 0 0-.617-1.25a.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057a19.9 19.9 0 0 0 5.993 3.03a.078.078 0 0 0 .084-.028a14.09 14.09 0 0 0 1.226-1.994a.076.076 0 0 0-.041-.106a13.107 13.107 0 0 1-1.872-.892a.077.077 0 0 1-.008-.128a10.2 10.2 0 0 0 .372-.292a.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127a12.299 12.299 0 0 1-1.873.892a.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028a19.839 19.839 0 0 0 6.002-3.03a.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419c0-1.333.956-2.419 2.157-2.419c1.21 0 2.176 1.096 2.157 2.42c0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419c0-1.333.955-2.419 2.157-2.419c1.21 0 2.176 1.096 2.157 2.42c0 1.333-.946 2.418-2.157 2.418z" />
                </svg>
                @mimoimior
              </a>
            </Button>
            <Button
              variant="outline"
              className="rounded-full hover:bg-primary/10 hover:text-primary hover:border-primary/50 transition-colors"
              asChild
            >
              <a href="mailto:mimoimior@gmail.com" className="flex items-center gap-2">
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                </svg>
                mimoimior@gmail.com
              </a>
            </Button>
          </div>

          <Separator className="w-1/2" />

          <p className="text-sm text-muted-foreground">
            © {new Date().getFullYear()} Mimoimior.
          </p>
        </div>
      </footer>
    </div>
  );
}

export default App;
