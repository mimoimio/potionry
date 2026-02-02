import { motion } from "framer-motion";
import { pricingTiers } from "../lib/data";
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "./ui/card";
import { Badge } from "./ui/badge";
import { Button } from "./ui/button";
import { Check, Sparkles } from "lucide-react";

export function Pricing() {
    return (
        <section className="py-20 relative overflow-hidden bg-muted/30">
            {/* Background */}
            <div className="absolute inset-0 bg-[url(/bg.png)] bg-center bg-fixed bg-cover opacity-20" />
            <div className="absolute inset-0 bg-[linear-gradient(to_right,#80808012_1px,transparent_1px),linear-gradient(to_bottom,#80808012_1px,transparent_1px)] bg-[size:24px_24px]" />

            <div className="container mx-auto px-4 relative z-10">
                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                    className="text-center mb-16 space-y-4"
                >
                    <h2 className="text-3xl md:text-5xl font-bold tracking-tight">
                        Commission <span className="text-primary">Pricing</span>
                    </h2>
                    <p className="text-muted-foreground text-lg max-w-2xl mx-auto">
                        Flexible pricing for projects of any scale. All packages include clean code and documentation.
                    </p>
                </motion.div>

                <div className="grid md:grid-cols-3 gap-6 max-w-6xl mx-auto">
                    {pricingTiers.map((tier, index) => (
                        <motion.div
                            key={tier.id}
                            initial={{ opacity: 0, y: 50 }}
                            whileInView={{ opacity: 1, y: 0 }}
                            viewport={{ once: true }}
                            transition={{ duration: 0.5, delay: index * 0.1 }}
                        >
                            <Card className={`h-full flex flex-col relative ${tier.popular ? 'border-primary/50 shadow-xl shadow-primary/10' : 'hover:border-primary/30'} transition-all duration-300`}>
                                {tier.popular && (
                                    <div className="absolute -top-4 left-1/2 -translate-x-1/2">
                                        <Badge className="bg-primary text-primary-foreground flex items-center gap-1 px-4 py-1">
                                            <Sparkles className="w-3 h-3" />
                                            Popular Choice
                                        </Badge>
                                    </div>
                                )}

                                <CardHeader>
                                    <div className="flex justify-between items-start mb-2">
                                        <CardTitle className="text-2xl">{tier.name}</CardTitle>
                                        <Badge
                                            variant="outline"
                                            className={
                                                tier.badgeColor === "green" ? "bg-green-500/10 text-green-500 border-green-500/20" :
                                                    tier.badgeColor === "blue" ? "bg-blue-500/10 text-blue-500 border-blue-500/20" :
                                                        "bg-purple-500/10 text-purple-500 border-purple-500/20"
                                            }
                                        >
                                            {tier.badge}
                                        </Badge>
                                    </div>
                                    <div className="mb-4">
                                        <span className="text-4xl font-bold text-primary">{tier.price}</span>
                                        {tier.price.includes("$") && <span className="text-muted-foreground ml-2">USD</span>}
                                    </div>
                                    <CardDescription className="text-base">
                                        {tier.description}
                                    </CardDescription>
                                </CardHeader>

                                <CardContent className="flex-grow">
                                    <ul className="space-y-3">
                                        {tier.features.map((feature, idx) => (
                                            <motion.li
                                                key={idx}
                                                initial={{ opacity: 0, x: -10 }}
                                                whileInView={{ opacity: 1, x: 0 }}
                                                viewport={{ once: true }}
                                                transition={{ delay: (index * 0.1) + (idx * 0.05) }}
                                                className="flex items-start gap-3"
                                            >
                                                <div className="rounded-full bg-primary/10 p-1 mt-0.5">
                                                    <Check className="w-4 h-4 text-primary" />
                                                </div>
                                                <span className="text-sm text-muted-foreground flex-1">{feature}</span>
                                            </motion.li>
                                        ))}
                                    </ul>
                                </CardContent>

                                <CardFooter>
                                    <Button
                                        className="w-full rounded-full group relative overflow-hidden"
                                        variant={tier.popular ? "default" : "outline"}
                                        size="lg"
                                        asChild
                                    >
                                        {tier.cta === "Contact Me" ? (
                                            <button onClick={() => document.getElementById('contact')?.scrollIntoView({ behavior: 'smooth' })}>
                                                {tier.cta}
                                            </button>
                                        ) : (
                                            <a href="https://discord.com/users/1463515044812820589" target="_blank" rel="noopener noreferrer">
                                                {tier.cta}
                                            </a>
                                        )}
                                    </Button>
                                </CardFooter>
                            </Card>
                        </motion.div>
                    ))}
                </div>

                <motion.div
                    initial={{ opacity: 0 }}
                    whileInView={{ opacity: 1 }}
                    viewport={{ once: true }}
                    transition={{ delay: 0.5 }}
                    className="text-center mt-12"
                >
                    <p className="text-sm text-muted-foreground">
                        All prices are negotiable. Payment accepted via PayPal or Robux.
                    </p>
                </motion.div>
            </div>
        </section>
    );
}
