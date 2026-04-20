import { ArrowRight, Shield, MapPin, Bell, Play } from "lucide-react";
import { Button } from "@/components/ui/button";
import appScreenshot from "@/assets/app-screenshot-1.png";

const Hero = () => {
  return (
    <section className="relative pt-24 lg:pt-32 pb-20 lg:pb-32 bg-background overflow-hidden">
      <div className="section-container relative z-10">
        <div className="grid lg:grid-cols-2 gap-12 lg:gap-20 items-center">
          {/* Content */}
          <div className="space-y-8">
            {/* Badge */}
            <div
              className="inline-flex items-center gap-2 px-4 py-2 bg-primary/5 border border-primary/20 rounded-full animate-fade-in-down"
              style={{ animationDelay: '0.1s' }}
            >
              <span className="relative flex h-2 w-2">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-primary opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2 w-2 bg-primary"></span>
              </span>
              <span className="text-sm font-medium text-foreground/80">
                Hecho en Chile, para municipios chilenos
              </span>
            </div>

            {/* Headline */}
            <div className="space-y-4 animate-fade-in-up" style={{ animationDelay: '0.2s' }}>
              <h1 className="text-4xl md:text-5xl lg:text-6xl xl:text-7xl font-black text-foreground leading-[1.1] tracking-tight">
                Gestión municipal{" "}
                <span className="text-primary">inteligente</span>
              </h1>
            </div>

            {/* Description */}
            <p
              className="text-lg lg:text-xl text-muted-foreground leading-relaxed max-w-xl animate-fade-in-up"
              style={{ animationDelay: '0.3s' }}
            >
              FROGIO conecta ciudadanos con su municipalidad. Denuncias,
              fiscalización y seguridad ciudadana en una sola plataforma
              <span className="text-primary font-medium"> moderna y eficiente</span>.
            </p>

            {/* CTA Buttons */}
            <div
              className="flex flex-col sm:flex-row gap-4 animate-fade-in-up"
              style={{ animationDelay: '0.4s' }}
            >
              <Button
                size="lg"
                className="group bg-primary hover:bg-primary/90 text-primary-foreground font-semibold px-8 h-14 text-base transition-all duration-300"
              >
                <span className="flex items-center gap-2">
                  Solicitar Demo
                  <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
                </span>
              </Button>
              <Button
                size="lg"
                variant="outline"
                className="group border-2 border-border hover:border-primary/50 text-foreground hover:bg-primary/5 font-medium px-8 h-14 text-base transition-all duration-300"
              >
                <Play className="w-5 h-5 mr-2 text-primary group-hover:scale-110 transition-transform" />
                Ver Funcionalidades
              </Button>
            </div>

            {/* Stats */}
            <div
              className="flex flex-wrap gap-8 lg:gap-12 pt-4 animate-fade-in-up"
              style={{ animationDelay: '0.5s' }}
            >
              {[
                { icon: Shield, label: "Seguridad", value: "24/7" },
                { icon: MapPin, label: "Geolocalización", value: "Tiempo real" },
                { icon: Bell, label: "Alertas", value: "Instantáneas" },
              ].map((stat, index) => (
                <div
                  key={stat.label}
                  className="group flex items-center gap-4 cursor-default"
                  style={{ animationDelay: `${0.6 + index * 0.1}s` }}
                >
                  <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center group-hover:bg-primary/20 transition-colors duration-300">
                    <stat.icon className="w-5 h-5 text-primary" />
                  </div>
                  <div>
                    <p className="text-xs text-muted-foreground uppercase tracking-wider">{stat.label}</p>
                    <p className="font-bold text-foreground">{stat.value}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* App Screenshot */}
          <div className="relative animate-scale-in lg:animate-fade-in-right" style={{ animationDelay: '0.3s' }}>
            {/* Phone mockup - clean, no extra frame */}
            <div className="relative mx-auto w-[300px] lg:w-[380px]">
              <img
                src={appScreenshot}
                alt="FROGIO App"
                className="w-full h-auto drop-shadow-2xl"
              />
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default Hero;
