import 'leaflet';

declare module 'leaflet' {
  namespace Control {
    class Draw extends Control {
      constructor(options?: DrawConstructorOptions);
    }

    interface DrawConstructorOptions {
      position?: ControlPosition;
      draw?: DrawOptions;
      edit?: EditOptions;
    }

    interface DrawOptions {
      polyline?: DrawOptions.PolylineOptions | false;
      polygon?: DrawOptions.PolygonOptions | false;
      rectangle?: DrawOptions.RectangleOptions | false;
      circle?: DrawOptions.CircleOptions | false;
      marker?: DrawOptions.MarkerOptions | false;
      circlemarker?: DrawOptions.CircleMarkerOptions | false;
    }

    namespace DrawOptions {
      interface PolylineOptions {
        allowIntersection?: boolean;
        drawError?: DrawErrorOptions;
        guidelineDistance?: number;
        maxGuideLineLength?: number;
        shapeOptions?: PathOptions;
        metric?: boolean;
        zIndexOffset?: number;
        repeatMode?: boolean;
      }

      interface PolygonOptions extends PolylineOptions {
        showArea?: boolean;
        showLength?: boolean;
      }

      interface RectangleOptions {
        shapeOptions?: PathOptions;
        repeatMode?: boolean;
      }

      interface CircleOptions {
        shapeOptions?: PathOptions;
        repeatMode?: boolean;
        showRadius?: boolean;
        metric?: boolean;
      }

      interface MarkerOptions {
        icon?: Icon;
        zIndexOffset?: number;
        repeatMode?: boolean;
      }

      interface CircleMarkerOptions {
        stroke?: boolean;
        color?: string;
        weight?: number;
        opacity?: number;
        fill?: boolean;
        fillColor?: string;
        fillOpacity?: number;
        clickable?: boolean;
        zIndexOffset?: number;
        repeatMode?: boolean;
      }

      interface DrawErrorOptions {
        color?: string;
        timeout?: number;
        message?: string;
      }
    }

    interface EditOptions {
      featureGroup: FeatureGroup;
      remove?: boolean;
      edit?: EditHandlerOptions | false;
    }

    interface EditHandlerOptions {
      selectedPathOptions?: PathOptions;
    }
  }

  namespace Draw {
    namespace Event {
      const CREATED: string;
      const EDITED: string;
      const DELETED: string;
      const DRAWSTART: string;
      const DRAWSTOP: string;
      const DRAWVERTEX: string;
      const EDITSTART: string;
      const EDITMOVE: string;
      const EDITRESIZE: string;
      const EDITVERTEX: string;
      const EDITSTOP: string;
      const DELETESTART: string;
      const DELETESTOP: string;
    }
  }

  namespace DrawEvents {
    interface Created extends LeafletEvent {
      layer: Layer;
      layerType: string;
    }

    interface Edited extends LeafletEvent {
      layers: LayerGroup;
    }

    interface Deleted extends LeafletEvent {
      layers: LayerGroup;
    }
  }
}

declare module 'leaflet-draw' {
  // This module augments leaflet
}
