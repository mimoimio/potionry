import { Hammer, Database, Layout, Map, Move, Code, Package, Zap } from 'lucide-react';

export const projects = [
    {
        id: 1,
        title: "Crafting System",
        description: "A comprehensive crafting mechanic allowing players to combine ingredients. Built with procedural recipe definitions.",
        icon: Hammer,
        tags: ["Crafting", "Procedural"],
        status: "Completed",
        // image: "/projects/craft.png", // Add your image path here
        video: "/projects/craft.mp4", // Or use video instead
    },
    {
        id: 2,
        title: "State-Synchronized Architecture",
        description: "Robust architecture featuring Datastore and Bus systems for seamless server-client state synchronization.",
        icon: Database,
        tags: ["Architecture", "Networking", "Reflex"],
        status: "Core",
        video: "/projects/state.mp4",
    },
    {
        id: 3,
        title: "Inventory System",
        description: "Declarative draggable inventory UI using React-Lua",
        icon: Layout,
        tags: ["React", "UI/UX", "Reflex"],
        status: "Completed",
        video: "/projects/inventory.mp4",
    },
    // {
    //     id: 4,
    //     title: "Plot Assigner",
    //     description: "Automated plot allocation system for tycoon or building games, handling ownership and serialization.",
    //     icon: Map,
    //     tags: ["Gameplay", "Tycoon", "Mgmt"],
    //     status: "Completed",
    //     image: "/projects/plot.png",
    // },
    {
        id: 5,
        title: "Throwing Mechanic",
        description: "Physics-based projectile system with calculated trajectories and server-side validation.",
        icon: Move,
        tags: ["Physics", "Combat", "Math"],
        status: "Prototype",
        video: "/projects/throw.mp4", // Example of using video
    }
];

export const skills = [
    { name: "Luau", icon: Code, level: "Expert" },
    { name: "Rojo", icon: Package, level: "Advanced" },
    { name: "React / Roact", icon: Layout, level: "Advanced" },
    { name: "Wally", icon: Package, level: "Intermediate" },
    { name: "TypeScript", icon: Code, level: "Intermediate" },
    { name: "Data Stores", icon: Database, level: "Expert" },
    { name: "Performance Optimization", icon: Zap, level: "Advanced" },
];
