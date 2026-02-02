import { motion } from "framer-motion";
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "./ui/card";
import { Badge } from "./ui/badge";
import { Button } from "./ui/button";
import { ExternalLink, Github, type LucideIcon } from "lucide-react";

interface ProjectProps {
    project: {
        id: number;
        title: string;
        description: string;
        icon: LucideIcon;
        tags: string[];
        status: string;
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
            <Card className="h-full flex flex-col hover:border-primary/50 transition-colors duration-300">
                <CardHeader>
                    <div className="flex justify-between items-start">
                        <div className="p-3 bg-primary/10 rounded-lg">
                            <Icon className="w-8 h-8 text-primary" />
                        </div>
                        <Badge variant="outline" className={
                            project.status === "Completed" ? "bg-green-500/10 text-green-500 border-green-500/20" :
                                project.status === "Core" ? "bg-blue-500/10 text-blue-500 border-blue-500/20" :
                                    "bg-yellow-500/10 text-yellow-500 border-yellow-500/20"
                        }>
                            {project.status}
                        </Badge>
                    </div>
                    <CardTitle className="mt-4 text-xl">{project.title}</CardTitle>
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
                <CardFooter className="gap-2">
                    <Button variant="outline" size="sm" className="w-full">
                        <Github className="w-4 h-4 mr-2" /> Code
                    </Button>
                    <Button size="sm" className="w-full">
                        <ExternalLink className="w-4 h-4 mr-2" /> View
                    </Button>
                </CardFooter>
            </Card>
        </motion.div>
    );
}
