import { Hammer, Database, Layout, Map, Move, Code, Package, Zap } from 'lucide-react';

export const projects = [
    {
        id: 1,
        title: "Crafting System",
        description: "A comprehensive crafting mechanic allowing players to combine items. Built with extensible recipe definitions.",
        icon: Hammer,
        tags: ["Roblox", "Lua", "Systems"],
        status: "Completed"
    },
    {
        id: 2,
        title: "Modular Framework",
        description: "Robust architecture featuring Datastore and Bus systems for seamless server-client state synchronization.",
        icon: Database,
        tags: ["Architecture", "Networking", "Data Sync"],
        status: "Core"
    },
    {
        id: 3,
        title: "Declarative React UI",
        description: "Modern user interface implementation using React-Lua (Roact) for component-based UI development.",
        icon: Layout,
        tags: ["React", "UI/UX", "Roact"],
        status: "Live"
    },
    {
        id: 4,
        title: "Plot Assigner",
        description: "Automated plot allocation system for tycoon or building games, handling ownership and serialization.",
        icon: Map,
        tags: ["Gameplay", "Tycoon", "Mgmt"],
        status: "Completed"
    },
    {
        id: 5,
        title: "Throwing Mechanic",
        description: "Physics-based projectile system with calculated trajectories and server-side validation.",
        icon: Move,
        tags: ["Physics", "Combat", "Math"],
        status: "Prototype"
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
