import { Heart, Github, Twitter, Linkedin, Instagram, MapPin, ArrowUpRight } from "lucide-react";
import frogioLogo from "@/assets/frogio-logo.png";

const Footer = () => {
  const currentYear = new Date().getFullYear();

  const footerLinks = {
    producto: [
      { label: "Funcionalidades", href: "#features" },
      { label: "Perfiles", href: "#profiles" },
      { label: "Precios", href: "#pricing" },
      { label: "Integraciones", href: "#integrations" },
    ],
    empresa: [
      { label: "Sobre Nosotros", href: "#about" },
      { label: "Blog", href: "#blog" },
      { label: "Careers", href: "#careers" },
      { label: "Contacto", href: "#contact" },
    ],
    legal: [
      { label: "Privacidad", href: "/privacidad" },
      { label: "Términos", href: "/terminos" },
      { label: "Eliminar cuenta", href: "/eliminacion" },
    ],
  };

  const socialLinks = [
    { icon: Twitter, href: "https://twitter.com/frogio", label: "Twitter" },
    { icon: Linkedin, href: "https://linkedin.com/company/frogio", label: "LinkedIn" },
    { icon: Instagram, href: "https://instagram.com/frogio", label: "Instagram" },
    { icon: Github, href: "https://github.com/frogio", label: "GitHub" },
  ];

  return (
    <footer className="relative bg-background overflow-hidden">
      {/* Decorative top border */}
      <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-primary/30 to-transparent" />

      {/* Background decorations */}
      <div className="absolute inset-0 pointer-events-none">
        <div className="absolute bottom-0 left-1/4 w-96 h-96 bg-primary/5 rounded-full blur-3xl" />
        <div className="absolute bottom-0 right-1/4 w-64 h-64 bg-accent/5 rounded-full blur-3xl" />
      </div>

      <div className="section-container relative z-10">
        {/* Main footer content */}
        <div className="py-16 lg:py-20">
          <div className="grid lg:grid-cols-12 gap-12 lg:gap-8">
            {/* Brand section */}
            <div className="lg:col-span-4">
              <a href="/" className="inline-flex items-center gap-3 group mb-6">
                <div className="relative">
                  <img
                    src={frogioLogo}
                    alt="Frogio"
                    className="h-12 w-auto transition-transform duration-300 group-hover:scale-110"
                  />
                  <div className="absolute inset-0 bg-primary/20 blur-xl opacity-0 group-hover:opacity-100 transition-opacity duration-300 rounded-full" />
                </div>
                <span className="text-2xl font-bold text-foreground tracking-tight group-hover:text-primary transition-colors duration-300">
                  FROGIO
                </span>
              </a>
              <p className="text-muted-foreground mb-6 max-w-sm leading-relaxed">
                Transformando la gestión municipal en Chile con tecnología moderna e inteligente.
              </p>

              {/* Location badge */}
              <div className="inline-flex items-center gap-2 px-4 py-2 bg-primary/5 border border-primary/10 rounded-full">
                <MapPin className="w-4 h-4 text-primary" />
                <span className="text-sm text-foreground/70">Santiago, Chile</span>
              </div>
            </div>

            {/* Links sections */}
            <div className="lg:col-span-8">
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-8 lg:gap-12">
                {/* Producto */}
                <div>
                  <h4 className="text-sm font-bold text-foreground uppercase tracking-wider mb-6">
                    Producto
                  </h4>
                  <ul className="space-y-4">
                    {footerLinks.producto.map((link) => (
                      <li key={link.label}>
                        <a
                          href={link.href}
                          className="group inline-flex items-center gap-1 text-muted-foreground hover:text-foreground transition-colors duration-300"
                        >
                          {link.label}
                          <ArrowUpRight className="w-3 h-3 opacity-0 -translate-y-1 translate-x-1 group-hover:opacity-100 group-hover:translate-y-0 group-hover:translate-x-0 transition-all duration-300" />
                        </a>
                      </li>
                    ))}
                  </ul>
                </div>

                {/* Empresa */}
                <div>
                  <h4 className="text-sm font-bold text-foreground uppercase tracking-wider mb-6">
                    Empresa
                  </h4>
                  <ul className="space-y-4">
                    {footerLinks.empresa.map((link) => (
                      <li key={link.label}>
                        <a
                          href={link.href}
                          className="group inline-flex items-center gap-1 text-muted-foreground hover:text-foreground transition-colors duration-300"
                        >
                          {link.label}
                          <ArrowUpRight className="w-3 h-3 opacity-0 -translate-y-1 translate-x-1 group-hover:opacity-100 group-hover:translate-y-0 group-hover:translate-x-0 transition-all duration-300" />
                        </a>
                      </li>
                    ))}
                  </ul>
                </div>

                {/* Legal */}
                <div>
                  <h4 className="text-sm font-bold text-foreground uppercase tracking-wider mb-6">
                    Legal
                  </h4>
                  <ul className="space-y-4">
                    {footerLinks.legal.map((link) => (
                      <li key={link.label}>
                        <a
                          href={link.href}
                          className="group inline-flex items-center gap-1 text-muted-foreground hover:text-foreground transition-colors duration-300"
                        >
                          {link.label}
                          <ArrowUpRight className="w-3 h-3 opacity-0 -translate-y-1 translate-x-1 group-hover:opacity-100 group-hover:translate-y-0 group-hover:translate-x-0 transition-all duration-300" />
                        </a>
                      </li>
                    ))}
                  </ul>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Bottom bar */}
        <div className="py-8 border-t border-border/50">
          <div className="flex flex-col sm:flex-row justify-between items-center gap-6">
            {/* Copyright */}
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <span>© {currentYear} FROGIO.</span>
              <span className="hidden sm:inline">•</span>
              <span className="flex items-center gap-1">
                Hecho con <Heart className="w-4 h-4 text-red-500 fill-red-500 animate-pulse" /> en Chile
              </span>
            </div>

            {/* Social links */}
            <div className="flex items-center gap-2">
              {socialLinks.map((social) => (
                <a
                  key={social.label}
                  href={social.href}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="group w-10 h-10 rounded-xl bg-muted/50 hover:bg-primary/10 flex items-center justify-center transition-all duration-300 hover:-translate-y-1"
                  aria-label={social.label}
                >
                  <social.icon className="w-5 h-5 text-muted-foreground group-hover:text-primary transition-colors duration-300" />
                </a>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Gradient fade at bottom */}
      <div className="absolute bottom-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-border to-transparent" />
    </footer>
  );
};

export default Footer;
