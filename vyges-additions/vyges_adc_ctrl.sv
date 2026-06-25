// Vyges integration wrapper for the OpenTitan adc_ctrl.
//
// Presents a clean digital surface to the SoC generator — clk/rst + TL-UL +
// the two interrupts — and absorbs the parts the generator should not have to
// know about:
//   - always-on clock/reset domain (clk_aon_i/rst_aon_ni) folded onto the core
//     clock/reset (V1.5: no separate 200 kHz AON domain),
//   - the AST analog front-end (adc_o/adc_i) left unwired — adc_i grounded,
//     adc_o open (no on-die ADC in this SoC),
//   - the alert sender pair terminated locally (alert_rx_i tied to the
//     prim_alert_pkg idle default, alert_tx_o open).
//
// This keeps the soc-generator wiring generic: the SoC top instantiates
// vyges_adc_ctrl with clk_i/rst_ni/tl_i/tl_o + intr_match_pending_o/wkup_req_o
// only, with no ast_pkg / prim_alert_pkg types crossing the SoC-top boundary.
//
// Note for the IP owner: adc_ctrl folds intg_err_o / reg2hw / hw2reg internally
// (they are reg_top<->core signals, not top-level ports) and exposes integrity
// faults via alert_tx_o — the Vyges metadata is corrected accordingly.
//
// SPDX-License-Identifier: Apache-2.0

module vyges_adc_ctrl
  import adc_ctrl_reg_pkg::*;
(
  input  wire                     clk_i,
  input  wire                     rst_ni,

  // Register interface (TL-UL device)
  input  tlul_pkg::tl_h2d_t       tl_i,
  output tlul_pkg::tl_d2h_t       tl_o,

  // Interrupts
  output logic                    intr_match_pending_o,
  output logic                    wkup_req_o
);

  adc_ctrl u_adc_ctrl (
    .clk_i      (clk_i),
    .clk_aon_i  (clk_i),              // V1.5: AON domain folded onto core clock
    .rst_ni     (rst_ni),
    .rst_aon_ni (rst_ni),
    .tl_i       (tl_i),
    .tl_o       (tl_o),
    // Alerts terminated locally (no alert receiver in this SoC build)
    .alert_rx_i ({NumAlerts{prim_alert_pkg::ALERT_RX_DEFAULT}}),
    .alert_tx_o (),
    // AST analog front-end not wired
    .adc_o      (),
    .adc_i      ('0),
    .intr_match_pending_o (intr_match_pending_o),
    .wkup_req_o (wkup_req_o)
  );

endmodule
