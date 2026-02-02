import { motion } from "framer-motion";
import { skills } from "../lib/data";

export function Skills() {
    return (
        <section className="py-20 bg-secondary/50">
            <div className="container mx-auto px-4">
                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                    className="text-center mb-12"
                >
                    <h2 className="text-3xl font-bold tracking-tight mb-4">Technical Arsenal</h2>
                    <p className="text-muted-foreground max-w-2xl mx-auto">
                        Tools and technologies I use to build scalable and performant experiences.
                    </p>
                </motion.div>

                <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-7 gap-4">
                    {skills.map((skill, index) => {
                        const Icon = skill.icon;
                        return (
                            <motion.div
                                key={skill.name}
                                initial={{ opacity: 0, scale: 0.9 }}
                                whileInView={{ opacity: 1, scale: 1 }}
                                viewport={{ once: true }}
                                transition={{ delay: index * 0.05 }}
                                className="flex flex-col items-center justify-center p-4 bg-background rounded-xl border hover:border-primary/50 transition-colors"
                            >
                                <div className="p-3 bg-muted rounded-full mb-3">
                                    <Icon className="w-6 h-6 text-foreground" />
                                </div>
                                <span className="font-medium text-sm text-center">{skill.name}</span>
                            </motion.div>
                        );
                    })}
                </div>
            </div>
        </section>
    );
}
