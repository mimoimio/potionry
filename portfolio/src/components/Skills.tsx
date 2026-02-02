import { motion } from "framer-motion";
import { skillCategories } from "../lib/data";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "./ui/card";
import { Badge } from "./ui/badge";

export function Skills() {
    return (
        <section className="py-20 relative overflow-hidden">
            {/* Background */}
            <div className="absolute inset-0 bg-[url(/bg.png)] bg-center bg-fixed bg-cover opacity-30" />
            <div className="absolute inset-0 bg-[linear-gradient(to_right,#80808012_1px,transparent_1px),linear-gradient(to_bottom,#80808012_1px,transparent_1px)] bg-[size:24px_24px]" />

            <div className="container mx-auto px-4 relative z-10">
                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                    className="text-center mb-16 space-y-4"
                >
                    <h2 className="text-3xl md:text-5xl font-bold tracking-tight">
                        Technical <span className="text-primary">Stack</span>
                    </h2>
                    <p className="text-muted-foreground text-lg max-w-2xl mx-auto">
                        Modern tooling and frameworks for building production-ready experiences.
                    </p>
                </motion.div>
                <div className="grid md:grid-cols-2 gap-6 max-w-5xl mx-auto">
                    {skillCategories.map((category, catIndex) => (
                        <motion.div
                            key={category.category}
                            initial={{ opacity: 0, x: catIndex === 0 ? -20 : 20 }}
                            whileInView={{ opacity: 1, x: 0 }}
                            viewport={{ once: true }}
                            transition={{ duration: 0.5, delay: catIndex * 0.1 }}
                        >
                            <Card className="h-full hover:border-primary/50 transition-colors">
                                <CardHeader>
                                    <CardTitle className="text-2xl flex items-center gap-2">
                                        {category.category}
                                        <Badge variant="outline" className="ml-auto">
                                            {category.skills.length}
                                        </Badge>
                                    </CardTitle>
                                    <CardDescription className="text-base">
                                        {category.description}
                                    </CardDescription>
                                </CardHeader>
                                <CardContent>
                                    <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                                        {category.skills.map((skill, index) => {
                                            const Icon = skill.icon;
                                            return (
                                                <motion.div
                                                    key={skill.name}
                                                    initial={{ opacity: 0, scale: 0.9 }}
                                                    whileInView={{ opacity: 1, scale: 1 }}
                                                    viewport={{ once: true }}
                                                    transition={{ delay: (catIndex * 0.3) + (index * 0.05) }}
                                                    whileHover={{ scale: 1.05 }}
                                                    className="flex flex-col items-center gap-2 p-3 bg-muted/50 rounded-lg hover:bg-muted transition-colors cursor-default"
                                                >
                                                    <div className="p-2 bg-primary/10 rounded-lg">
                                                        {skill.image ? (
                                                            <img src={skill.image} alt={skill.name} className="w-5 h-5 object-contain" />
                                                        ) : Icon ? (
                                                            <Icon className="w-5 h-5 text-primary" />
                                                        ) : null}
                                                    </div>
                                                    <span className="text-sm font-medium text-center">
                                                        {skill.name}
                                                    </span>
                                                </motion.div>
                                            );
                                        })}
                                    </div>
                                </CardContent>
                            </Card>
                        </motion.div>
                    ))}
                </div>
            </div>
        </section>
    );
}
