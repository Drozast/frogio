import { useEffect, useRef, useState } from "react";
import {
  Users,
  Shield,
  Settings,
  Megaphone,
  Target,
  AlertTriangle,
  Map,
  FileWarning,
  Car,
  BarChart3,
  Network,
  ShieldCheck,
  Sparkles,
  ArrowRight
} from "lucide-react";

interface ModuleCard {
  icon: React.ElementType;
  title: string;
  description: string;
  tags?: string[];
  variant?: "default" | "danger";
  buttonText: string;
}

interface ModuleSection {
  icon: React.ElementType;
  title: string;
  subtitle: string;
  gradient: string;
  bgGradient: string;
  cards: ModuleCard[];
}

const modules: ModuleSection[] = [
  {
    icon: Users,
    title: "Módulo Ciudadano",
    subtitle: "Empoderando a la comunidad con herramientas digitales",
    gradient: "from-primary to-emerald-light",
    bgGradient: "from-primary/10 to-emerald-light/5",
    cards: [
      {
        icon: Megaphone,
        title: "Denuncias Ciudadanas",
        description: "Reporte de incidencias urbanas con carga de evidencia multimedia y geolocalización precisa.",
        buttonText: "Ver más",
      },
      {
        icon: Target,
        title: "Seguimiento Real-Time",
        description: "Monitorea el estado de tus solicitudes y la ubicación de las cuadrillas municipales asignadas.",
        buttonText: "Ver más",
      },
      {
        icon: AlertTriangle,
        title: "Botón de Pánico",
        description: "Alerta inmediata a la Central de Seguridad Ciudadana con transmisión de audio y ubicación en vivo.",
        variant: "danger",
        buttonText: "Explorar",
      },
    ],
  },
  {
    icon: Shield,
    title: "Módulo Fiscalizador",
    subtitle: "Herramientas tácticas para inspectores de terreno",
    gradient: "from-accent to-navy-light",
    bgGradient: "from-accent/10 to-navy-light/5",
    cards: [
      {
        icon: Map,
        title: "Mapa de Incidencias",
        description: "Visualización cartográfica de reportes ciudadanos y puntos críticos para patrullaje inteligente.",
        buttonText: "Ver más",
      },
      {
        icon: FileWarning,
        title: "Emisión de Citaciones",
        description: "Gestión digital de partes y multas para Personas, Vehículos y Comercios de la comuna.",
        tags: ["Vehículos", "Patentes"],
        buttonText: "Explorar",
      },
      {
        icon: Car,
        title: "Bitácora de Vehículos",
        description: "Registro de recorridos, consumo de combustible y mantenimiento de la flota municipal.",
        buttonText: "Ver más",
      },
    ],
  },
  {
    icon: Settings,
    title: "Módulo Administrativo",
    subtitle: "Control centralizado y analítica de gestión",
    gradient: "from-violet-500 to-purple-600",
    bgGradient: "from-violet-500/10 to-purple-600/5",
    cards: [
      {
        icon: BarChart3,
        title: "Panel de Control KPI",
        description: "Dashboard interactivo con indicadores clave de desempeño y reportes de eficiencia operativa.",
        buttonText: "Ver más",
      },
      {
        icon: Network,
        title: "Gestión Multi-Tenant",
        description: "Control integral de diversas direcciones municipales bajo un mismo entorno administrativo seguro.",
        buttonText: "Explorar",
      },
      {
        icon: ShieldCheck,
        title: "Auditoría de Sistema",
        description: "Trazabilidad completa de acciones y cambios realizados por usuarios para máxima transparencia.",
        buttonText: "Ver más",
      },
    ],
  },
];

const ModuleCardComponent = ({ card, sectionGradient, index }: { card: ModuleCard; sectionGradient: string; index: number }) => {
  const isDanger = card.variant === "danger";
  const cardGradient = isDanger ? "from-red-500 to-orange-500" : sectionGradient;
  const cardBgGradient = isDanger ? "from-red-500/10 to-orange-500/5" : `${sectionGradient.replace('to-', 'to-').split(' ')[0]}/10 ${sectionGradient.split(' ')[1]}/5`;

  return (
    <div
      className="group relative p-6 lg:p-8 rounded-3xl border border-border/50 bg-background hover:border-primary/30 transition-all duration-500 flex flex-col h-full cursor-default hover:-translate-y-2 hover:shadow-xl"
      style={{ animationDelay: `${index * 0.1}s` }}
    >
      {/* Gradient background on hover */}
      <div className={`absolute inset-0 bg-gradient-to-br ${isDanger ? "from-red-500/10 to-orange-500/5" : cardBgGradient} opacity-0 group-hover:opacity-100 transition-opacity duration-500 rounded-3xl`} />

      {/* Content */}
      <div className="relative z-10 flex flex-col h-full">
        {/* Icon */}
        <div className={`relative w-14 h-14 rounded-2xl bg-gradient-to-br ${cardGradient} p-[1px] mb-6 group-hover:scale-110 group-hover:rotate-3 transition-all duration-500`}>
          <div className="w-full h-full bg-background rounded-[15px] flex items-center justify-center group-hover:bg-transparent transition-colors duration-300">
            <card.icon className={`w-7 h-7 transition-colors duration-300 ${isDanger ? "text-red-500 group-hover:text-white" : "text-foreground group-hover:text-white"}`} />
          </div>
          {/* Glow */}
          <div className={`absolute inset-0 bg-gradient-to-br ${cardGradient} blur-xl opacity-0 group-hover:opacity-40 transition-opacity duration-500 rounded-2xl`} />
        </div>

        {/* Title */}
        <h3 className={`text-xl font-bold mb-3 transition-colors duration-300 ${isDanger ? "text-foreground group-hover:text-red-500" : "text-foreground group-hover:text-primary"}`}>
          {card.title}
        </h3>

        {/* Description */}
        <p className="text-muted-foreground leading-relaxed mb-4 flex-grow group-hover:text-foreground/80 transition-colors">
          {card.description}
        </p>

        {/* Tags */}
        {card.tags && (
          <div className="flex flex-wrap gap-2 mb-6">
            {card.tags.map((tag) => (
              <span
                key={tag}
                className="px-3 py-1 rounded-full bg-muted/50 text-xs font-semibold text-muted-foreground uppercase tracking-wide group-hover:bg-primary/10 group-hover:text-primary transition-colors duration-300"
              >
                {tag}
              </span>
            ))}
          </div>
        )}

        {/* Button */}
        <button className={`w-full py-3.5 rounded-xl transition-all duration-300 text-sm font-bold border flex items-center justify-center gap-2 ${
          isDanger
            ? "bg-muted/50 border-border hover:bg-red-500 hover:text-white hover:border-red-500 group-hover:bg-red-500/10"
            : "bg-muted/50 border-border hover:bg-primary hover:text-white hover:border-primary group-hover:border-primary/20"
        }`}>
          {card.buttonText}
          <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
        </button>
      </div>
    </div>
  );
};

const ModuleSectionComponent = ({ section, sectionIndex }: { section: ModuleSection; sectionIndex: number }) => {
  const [isVisible, setIsVisible] = useState(false);
  const sectionRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting) {
          setIsVisible(true);
        }
      },
      { threshold: 0.1 }
    );

    if (sectionRef.current) {
      observer.observe(sectionRef.current);
    }

    return () => observer.disconnect();
  }, []);

  return (
    <div
      ref={sectionRef}
      className={`mb-20 last:mb-0 transition-all duration-700 ${isVisible ? "opacity-100 translate-y-0" : "opacity-0 translate-y-8"}`}
      style={{ transitionDelay: `${sectionIndex * 0.2}s` }}
    >
      {/* Section header */}
      <div className="flex items-center gap-4 mb-10">
        <div className={`relative w-14 h-14 rounded-2xl bg-gradient-to-br ${section.gradient} p-[1px]`}>
          <div className="w-full h-full bg-background rounded-[15px] flex items-center justify-center">
            <section.icon className="w-7 h-7 text-foreground" />
          </div>
          <div className={`absolute inset-0 bg-gradient-to-br ${section.gradient} blur-xl opacity-30 rounded-2xl`} />
        </div>
        <div className="flex-1">
          <h2 className="text-2xl font-black text-foreground">{section.title}</h2>
          <p className="text-muted-foreground text-sm">{section.subtitle}</p>
        </div>
        <div className={`flex-grow h-px bg-gradient-to-r ${section.gradient} opacity-20 ml-4 hidden lg:block`} />
      </div>

      {/* Cards grid */}
      <div className="grid md:grid-cols-3 gap-6">
        {section.cards.map((card, index) => (
          <ModuleCardComponent
            key={card.title}
            card={card}
            sectionGradient={section.gradient}
            index={index}
          />
        ))}
      </div>
    </div>
  );
};

const Modules = () => {
  return (
    <div className="py-4">
      {/* Header */}
      <div className="text-center mb-16">
        <div className="inline-flex items-center gap-2 px-4 py-2 bg-gradient-to-r from-primary/10 to-violet-500/10 border border-primary/20 rounded-full mb-6">
          <Sparkles className="w-4 h-4 text-primary" />
          <span className="text-sm font-bold text-foreground uppercase tracking-wider">Ecosistema Frogio</span>
        </div>
        <h2 className="text-3xl md:text-4xl lg:text-5xl font-black text-foreground mb-6">
          Nuestros Módulos{" "}
          <span className="bg-gradient-to-r from-primary via-accent to-violet-500 bg-clip-text text-transparent">
            Especializados
          </span>
        </h2>
        <p className="text-muted-foreground max-w-2xl mx-auto text-lg leading-relaxed">
          Una plataforma modular diseñada para integrar a todos los actores municipales en una sola experiencia digital coherente y eficiente.
        </p>
      </div>

      {/* Module Sections */}
      {modules.map((section, index) => (
        <ModuleSectionComponent key={section.title} section={section} sectionIndex={index} />
      ))}
    </div>
  );
};

export default Modules;
