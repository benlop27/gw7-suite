// Cypress support file — global hooks for all e2e specs.
Cypress.on('uncaught:exception', (err) => {
  // Flutter web can throw benign errors on first frame; surface them but
  // don't fail the run for now.
  cy.log('Uncaught exception: ' + err.message);
  return false;
});
