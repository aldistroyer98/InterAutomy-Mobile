import '../../domain/entities/client.dart';
import '../../domain/entities/commercial_line.dart';
import '../../domain/entities/comodato.dart';
import '../../domain/entities/product.dart';

abstract final class DemoSeed {
  static const abbott = CommercialLine(
    id: 'abbott-hematologia',
    nombre: 'ABBOTT HEMATOLOGÍA',
  );
  static const roche = CommercialLine(
    id: 'roche-quimica',
    nombre: 'ROCHE QUÍMICA',
  );
  static const biomerieux = CommercialLine(
    id: 'biomerieux-microbiologia',
    nombre: 'BIOMERIEUX MICROBIOLOGÍA',
  );

  static const comodatoAbbott = Comodato(
    id: 'cmd-abbott-01',
    codigo: 'CMD240054',
    nombre: 'Analizador hematológico',
  );
  static const comodatoRoche = Comodato(
    id: 'cmd-roche-01',
    codigo: 'CMD240128',
    nombre: 'Analizador Cobas',
  );
  static const comodatoBio = Comodato(
    id: 'cmd-bio-01',
    codigo: 'CMD240211',
    nombre: 'Sistema VITEK',
  );
  static const comodatoGeneral = Comodato(
    id: 'cmd-general-01',
    codigo: 'CMD-GENERAL',
    nombre: 'Equipo general',
    esGeneral: true,
  );

  static const lines = [abbott, roche, biomerieux];

  static const clients = [
    Client(
      id: 'client-san-borja',
      nombre: 'San Borja',
      unidad: 'Laboratorio Central',
      servicio: 'Patología Clínica',
      institucion: 'Hospital San Borja',
      departamento: 'Lima',
      provincia: 'Lima',
      distrito: 'San Borja',
      direccion: 'Av. San Borja Norte 801',
      contacto: 'María Torres',
      telefono: '999 100 101',
      comentarioFinal: 'Coordinar entrega con almacén.',
      igv: true,
      comodatosPorLinea: {
        'abbott-hematologia': [comodatoAbbott],
        'roche-quimica': [comodatoRoche],
      },
    ),
    Client(
      id: 'client-miraflores',
      nombre: 'Miraflores',
      unidad: 'Laboratorio',
      servicio: 'Bioquímica',
      institucion: 'Clínica Miraflores',
      departamento: 'Lima',
      provincia: 'Lima',
      distrito: 'Miraflores',
      direccion: 'Av. Pardo 550',
      contacto: 'Carlos Rojas',
      telefono: '999 200 202',
      moneda: 'Dólares',
      comodatosPorLinea: {
        'roche-quimica': [comodatoRoche],
        'general': [comodatoGeneral],
      },
    ),
    Client(
      id: 'client-surco',
      nombre: 'Surco',
      unidad: 'Diagnóstico',
      servicio: 'Microbiología',
      institucion: 'Centro Médico Surco',
      departamento: 'Lima',
      provincia: 'Lima',
      distrito: 'Santiago de Surco',
      direccion: 'Av. El Polo 740',
      contacto: 'Ana Salazar',
      telefono: '999 300 303',
      comodatosPorLinea: {
        'biomerieux-microbiologia': [comodatoBio],
      },
    ),
  ];

  static final products = <CatalogProduct>[
    const CatalogProduct(
      id: 'p-abbott-01',
      codigo: 'ABT-HGB-001',
      nombre: 'Cell-Dyn Hemoglobin Reagent',
      descripcion: 'Reactivo para determinación de hemoglobina',
      linea: abbott,
      presentacion: 'Caja x 4 frascos',
      precio: 485.50,
      categoria: 'Reactivos principales',
      requiereComodato: true,
    ),
    const CatalogProduct(
      id: 'p-abbott-02',
      codigo: 'ABT-CBC-002',
      nombre: 'Control Hematológico Tri-Nivel',
      descripcion: 'Control de tres niveles',
      linea: abbott,
      presentacion: 'Kit x 6 viales',
      precio: 720,
      categoria: 'Controles y calibradores',
      requiereComodato: true,
    ),
    const CatalogProduct(
      id: 'p-roche-01',
      codigo: 'RCH-GLU-010',
      nombre: 'Glucosa Gen.2',
      descripcion: 'Reactivo de glucosa para Cobas',
      linea: roche,
      presentacion: 'Cobas c pack',
      precio: 315.90,
      categoria: 'Reactivos principales',
      requiereComodato: true,
    ),
    const CatalogProduct(
      id: 'p-roche-02',
      codigo: 'RCH-CAL-011',
      nombre: 'Calibrator for Automated Systems',
      descripcion: 'Calibrador multiparámetro',
      linea: roche,
      presentacion: '12 x 3 ml',
      precio: 598,
      categoria: 'Controles y calibradores',
      requiereComodato: true,
    ),
    const CatalogProduct(
      id: 'p-bio-01',
      codigo: 'BIO-AST-020',
      nombre: 'VITEK 2 AST Card',
      descripcion: 'Tarjetas para sensibilidad antimicrobiana',
      linea: biomerieux,
      presentacion: 'Caja x 20 tarjetas',
      precio: 890,
      categoria: 'Reactivos principales',
      requiereComodato: true,
    ),
    const CatalogProduct(
      id: 'p-bio-02',
      codigo: 'BIO-ID-021',
      nombre: 'VITEK 2 GN ID Card',
      descripcion: 'Identificación de bacilos gramnegativos',
      linea: biomerieux,
      presentacion: 'Caja x 20 tarjetas',
      precio: 845,
      categoria: 'Reactivos principales',
      requiereComodato: true,
    ),
    const CatalogProduct(
      id: 'p-general-01',
      codigo: 'LAB-TUBE-030',
      nombre: 'Tubos de muestra',
      descripcion: 'Tubos plásticos de laboratorio',
      linea: abbott,
      presentacion: 'Bolsa x 100 unidades',
      precio: 75,
      categoria: 'Consumibles',
    ),
  ];
}
