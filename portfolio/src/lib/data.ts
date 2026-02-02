import { Hammer, Database, Layout, Move, Package } from 'lucide-react';
import { SiLua, SiReact, SiNextdotjs, SiLaravel, SiPython } from 'react-icons/si';

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
        description: "Robust architecture featuring Datastore and Bus Systems for seamless server-client state synchronization.",
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
        tags: ["Physics"],
        status: "Prototype",
        video: "/projects/throw.mp4", // Example of using video
    }
];

export const skillCategories = [
    {
        category: "Core Stack",
        description: "Foundation for building scalable Roblox experiences with modern architecture patterns.",
        skills: [
            { name: "Luau", icon: SiLua },
            { name: "Services Architecture", icon: Package },
            { name: "ProfileStore by loleris", icon: Database },
            { name: "React-Lua", image: "/React-lua.png" },
            { name: "Reflex", image: "/reflex.svg" },
        ]
    },
    {
        category: "Web & Backend",
        description: "Leveraging professional web standards like the Model-View-Controller architecure to build optimized, state-managed architectures within Roblox.",
        skills: [
            { name: "React", icon: SiReact },
            { name: "Next.js", icon: SiNextdotjs },
            { name: "Laravel", icon: SiLaravel },
            { name: "Python", icon: SiPython },
        ]
    }
];
