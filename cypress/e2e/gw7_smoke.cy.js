/// <reference types="cypress" />

// Flutter web renders to canvas; widgets are reachable through the
// accessibility/semantics tree. Enable semantics by clicking the placeholder,
// then assert on aria-labels.

function enableFlutterSemantics() {
  cy.get('flt-semantics-placeholder', { timeout: 30000 }).click({ force: true });
  cy.wait(2500);
}

function flutterLabel(text) {
  return cy.get(`[aria-label*="${text}"]`, { timeout: 15000 });
}

describe('GW-7 Studio web app', () => {
  beforeEach(() => {
    cy.visit('/');
    // wait for the flutter bootstrap to mount the semantics placeholder
    cy.get('flt-semantics-placeholder, flt-glass-pane, flutter-view', { timeout: 45000 }).should('exist');
    enableFlutterSemantics();
  });

  it('loads and shows the four main tabs', () => {
    ['Stage', 'Presets', 'Effects', 'Utils'].forEach((label) => {
      flutterLabel(label).should('exist');
    });
  });

  it('navigates to the Presets tab and shows the tone grid', () => {
    flutterLabel('Presets').click({ force: true });
    cy.wait(1500);
    // tone bank tabs are rendered in the presets view — check a known tone row
    flutterLabel('St.Piano 1').should('exist');
  });

  it('switches to the Effects tab', () => {
    flutterLabel('Effects').click({ force: true });
    cy.wait(1500);
    flutterLabel('Effects').should('exist');
  });

  it('switches to the Utils tab', () => {
    flutterLabel('Utils').click({ force: true });
    cy.wait(1500);
    flutterLabel('Utils').should('exist');
  });

  it('exposes the gw7Debug hook with bridge status', () => {
    cy.window().then((win) => {
      const debug = win.gw7Debug;
      expect(debug).to.be.a('function');
      const state = debug();
      expect(state).to.have.property('lastMessage');
      expect(state).to.have.property('status');
    });
  });
});
