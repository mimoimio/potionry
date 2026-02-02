import { motion } from "framer-motion";
import { Button } from "./ui/button";
import { ArrowDown, Clock } from "lucide-react";
import { useState, useEffect } from "react";

export function Hero() {
    const [malaysiaTime, setMalaysiaTime] = useState("");

    useEffect(() => {
        const updateTime = () => {
            const now = new Date();
            const malaysiaTimeStr = now.toLocaleTimeString("en-US", {
                timeZone: "Asia/Kuala_Lumpur",
                hour: "2-digit",
                minute: "2-digit",
                hour12: true,
                second: "2-digit",
            });
            setMalaysiaTime(malaysiaTimeStr);
        };

        updateTime();
        const interval = setInterval(updateTime, 1000);

        return () => clearInterval(interval);
    }, []);

    return (
        <section className="min-h-screen flex flex-col items-center justify-center p-4 relative overflow-hidden bg-background">
            {/* Background Image */}
            <div className="absolute inset-0 bg-[url(/bg.png)] bg-center bg-fixed bg-cover opacity-30" />

            {/* Animated Grid Background */}
            <div className="absolute inset-0 bg-[linear-gradient(to_right,#80808012_1px,transparent_1px),linear-gradient(to_bottom,#80808012_1px,transparent_1px)] bg-[size:24px_24px]" />

            {/* Gradient Orbs */}
            <motion.div
                animate={{
                    scale: [1, 1.2, 1],
                    opacity: [0.3, 0.5, 0.3],
                }}
                transition={{
                    duration: 8,
                    repeat: Infinity,
                    ease: "easeInOut",
                }}
                className="absolute top-1/4 -left-20 w-96 h-96 bg-primary/30 rounded-full blur-[100px]"
            />
            <motion.div
                animate={{
                    scale: [1, 1.3, 1],
                    opacity: [0.2, 0.4, 0.2],
                }}
                transition={{
                    duration: 10,
                    repeat: Infinity,
                    ease: "easeInOut",
                    delay: 1,
                }}
                className="absolute bottom-1/4 -right-20 w-96 h-96 bg-red-500/20 rounded-full blur-[120px]"
            />

            {/* Content */}
            <div className="z-10 text-white text-center max-w-4xl space-y-8">
                <motion.div
                    initial={{ scale: 5, opacity: 0, y: -40 }}
                    animate={{ scale: 1, opacity: 1, y: 0 }}
                    transition={{
                        duration: 1,
                        type: "spring",
                        bounce: 0.3
                    }}
                    className="inline-block"
                >
                    <div className="relative">
                        <span className="text-primary font-semibold tracking-[0.3em] text-xs md:text-sm uppercase">
                            Roblox Developer
                        </span>
                        <div className="absolute -inset-1 bg-primary/20 blur-xl rounded-full" />
                    </div>
                </motion.div>

                <motion.div
                    initial={{ opacity: 0, scale: 0.9 }}
                    animate={{ opacity: 1, scale: 1 }}
                    transition={{ duration: 0.5, delay: 0.1 }}
                    className="relative"
                >
                    <h1 className="text-6xl md:text-8xl lg:text-9xl font-black tracking-tighter relative">
                        <span className="bg-clip-text text-transparent bg-gradient-to-br from-white via-white to-white/60">
                            Mior's Portfolio
                        </span>
                        <div className="absolute -inset-4 bg-gradient-to-r from-primary/0 via-primary/30 to-primary/0 blur-2xl opacity-50" />
                    </h1>
                </motion.div>

                <motion.p
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.5, delay: 0.2 }}
                    className="text-muted-foreground/90 text-lg md:text-xl max-w-2xl mx-auto leading-relaxed"
                >
                    Specializing in <span className="text-primary font-semibold">scalable</span> and{" "}
                    <span className="text-primary font-semibold">modular frameworks</span>, and seamless user interfaces.
                </motion.p>

                <motion.div
                    initial={{ opacity: 0, scale: 0.95 }}
                    animate={{ opacity: 1, scale: 1 }}
                    transition={{ duration: 0.5, delay: 0.25 }}
                    className="flex flex-col justify-center items-center gap-3"
                >
                    <div className="inline-flex items-center gap-2 px-5 py-2.5 bg-muted/50 backdrop-blur-sm rounded-full border border-border/50">
                        <Clock className="w-4 h-4 text-primary" />
                        <span className="text-sm text-muted-foreground">My time now: </span>
                        <span className="text-md text-primary-foreground">{malaysiaTime} GMT+8</span>
                    </div>
                    <div className="inline-flex items-center gap-2 px-5 py-2.5 bg-muted/50 backdrop-blur-sm rounded-full border border-border/50">
                        <div className="w-2 h-2 rounded-full bg-primary animate-pulse" />
                        <span className="text-sm text-muted-foreground">1 year of luau scripting</span>
                    </div>
                    <div className="inline-flex items-center gap-2 px-5 py-2.5 bg-muted/50 backdrop-blur-sm rounded-full border border-border/50">
                        <div className="w-2 h-2 rounded-full bg-primary animate-pulse" />
                        <span className="text-sm text-muted-foreground">2 years of web dev</span>
                    </div>
                </motion.div>

                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.5, delay: 0.3 }}
                    className="flex gap-4 justify-center pt-4"
                >
                    <Button
                        size="lg"
                        className="rounded-full group relative overflow-hidden"
                        onClick={() => document.getElementById('projects')?.scrollIntoView({ behavior: 'smooth' })}
                    >
                        <span className="relative z-10">View Projects</span>
                        <div className="absolute inset-0 bg-gradient-to-r from-primary to-red-600 opacity-0 group-hover:opacity-100 transition-opacity" />
                    </Button>
                    <Button
                        variant="outline"
                        size="lg"
                        className="rounded-full border-border/50 hover:border-primary/50 backdrop-blur-sm"
                        onClick={() => document.getElementById('contact')?.scrollIntoView({ behavior: 'smooth' })}
                    >
                        Contact Me
                    </Button>
                </motion.div>
            </div>

            {/* Floating particles */}
            {[...Array(3)].map((_, i) => (
                <motion.div
                    key={i}
                    animate={{
                        y: [-20, 20, -20],
                        x: [-10, 10, -10],
                        opacity: [0.2, 0.5, 0.2],
                    }}
                    transition={{
                        duration: 5 + i,
                        repeat: Infinity,
                        ease: "easeInOut",
                        delay: i * 0.5,
                    }}
                    className="absolute w-2 h-2 bg-primary/50 rounded-full blur-sm"
                    style={{
                        left: `${20 + i * 30}%`,
                        top: `${30 + i * 20}%`,
                    }}
                />
            ))}

            <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 1, duration: 1 }}
                className="absolute bottom-10 animate-bounce"
            >
                <ArrowDown className="text-muted-foreground/70 w-6 h-6" />
            </motion.div>
        </section>
    );
}
