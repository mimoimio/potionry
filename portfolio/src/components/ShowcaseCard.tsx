import { motion } from "framer-motion";
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "./ui/card";
import { Badge } from "./ui/badge";
import { Button } from "./ui/button";
import { ExternalLink, Github, Image as ImageIcon, type LucideIcon } from "lucide-react";

interface ProjectProps {
    project: {
        id: number;
        title: string;
        description: string;
        icon: LucideIcon;
        tags: string[];
        status: string;
        image?: string;
        video?: string;
    };
    index: number;
}

export function ShowcaseCard({ project, index }: ProjectProps) {
    const Icon = project.icon;

    return (
        <motion.div
            initial={{ opacity: 0, y: 50 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: index * 0.1 }}
        >
            <Card className="h-full flex flex-col hover:border-primary/50 transition-colors duration-300 overflow-hidden">
                {/* Media Section */}
                <div className="relative w-full h-48 overflow-hidden group">
                    {project.video ? (
                        // Video
                        <>
                            <video
                                src={project.video}
                                className="w-full h-full object-cover"
                                autoPlay
                                muted
                                loop
                                playsInline
                            />
                            <div className="absolute inset-0 bg-gradient-to-t from-card via-transparent to-transparent opacity-80" />
                        </>
                    ) : project.image ? (
                        // Image
                        <>
                            <img
                                src={project.image}
                                alt={project.title}
                                className="w-full h-full object-cover transition-transform duration-300 group-hover:scale-105"
                            />
                            <div className="absolute inset-0 bg-gradient-to-t from-card via-transparent to-transparent opacity-80" />
                        </>
                    ) : (
                        // Placeholder
                        <>
                            <div className="w-full h-full bg-gradient-to-br from-primary/20 via-muted to-primary/10">
                                <div className="absolute inset-0 bg-[url('/grid.svg')] opacity-10" />
                                <motion.div
                                    className="absolute inset-0 flex items-center justify-center"
                                    whileHover={{ scale: 1.1 }}
                                    transition={{ duration: 0.3 }}
                                >
                                    <Icon className="w-16 h-16 text-primary/40" />
                                </motion.div>
                            </div>
                            <div className="absolute inset-0 bg-gradient-to-t from-card to-transparent opacity-80" />
                            <div className="absolute top-3 right-3 p-2 bg-background/80 backdrop-blur-sm rounded-lg opacity-0 group-hover:opacity-100 transition-opacity">
                                <ImageIcon className="w-4 h-4 text-muted-foreground" />
                            </div>
                        </>
                    )}
                </div>

                <CardHeader>
                    <div className="flex justify-between items-start">
                        <CardTitle className="text-xl">{project.title}</CardTitle>
                        <Badge variant="outline" className={
                            project.status === "Completed" ? "bg-green-500/10 text-green-500 border-green-500/20" :
                                project.status === "Core" ? "bg-blue-500/10 text-blue-500 border-blue-500/20" :
                                    "bg-yellow-500/10 text-yellow-500 border-yellow-500/20"
                        }>
                            {project.status}
                        </Badge>
                    </div>
                    <CardDescription className="line-clamp-2">
                        {project.description}
                    </CardDescription>
                </CardHeader>
                <CardContent className="flex-grow">
                    <div className="flex flex-wrap gap-2">
                        {project.tags.map(tag => (
                            <Badge key={tag} variant="secondary">
                                {tag}
                            </Badge>
                        ))}
                    </div>
                </CardContent>
                {/* <CardFooter className="gap-2">
                    <Button variant="outline" size="sm" className="w-full">
                        <Github className="w-4 h-4 mr-2" /> Code
                    </Button>
                    <Button size="sm" className="w-full">
                        <ExternalLink className="w-4 h-4 mr-2" /> View
                    </Button>
                </CardFooter> */}
            </Card>
        </motion.div>
    );
}
