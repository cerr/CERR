function plotTcpCurve(){
	/* This function plots the EQD2 vs TCP curve.
	APA, 11/22/2020
	*/
	// Plot TCP curve
   var eqd2V = [];
   for (var i = 0; i <= 300; i++) {
       eqd2V.push(i);
   }
   var TD_50 = 62.1
   var gamma_50 = 1.5
   var TCP_upper_bound = 0.95
   let tcpV = new Array(eqd2V.length-1)
   for (var i = 0; i <= eqd2V.length-1; i++) {
	   tcpV[i] = TCP_upper_bound / (1+Math.pow(TD_50/eqd2V[i],4*gamma_50));
   }
   var tcpCurve = {
     x: eqd2V,
     y: tcpV,
     type: 'lines',
     showlegend: false
   };

	var tcpPoint = {
	  x: [],
	  y: [],
	  type: 'scatter',
	  mode: 'markers',
	  marker: {
	    color: 'rgb(17, 157, 255)',
	    size: 20,
	    line: {
	      color: 'rgb(231, 99, 250)',
	      width: 2
	          }
	    },
	  showlegend: false
	};

var layout = {
  title: {
    text:'',
    font: {
      family: 'Courier New, monospace',
      size: 32,
      color: '#ff6961'
    },
    xref: 'paper',
    x: 0.05
  },
  xaxis: {
    title: {
      text: 'EQD2',
      font: {
        family: 'Courier New, monospace',
        size: 32,
        color: '#7f7f7f'
      }
    },
      tickfont: {
	        family: 'Courier New, monospace',
	        size: 24,
	        color: 'black'
	    }
  },
  yaxis: {
    title: {
      text: 'TCP',
      font: {
        family: 'Courier New, monospace',
        size: 30,
        color: '#7f7f7f'
      }
    },
      tickfont: {
	        family: 'Courier New, monospace',
	        size: 24,
	        color: 'black'
	    }
  }

  };

	var data = [ tcpCurve, tcpPoint ];

   Plotly.newPlot('tcpPlotDiv', data, layout);

   return;
};

function calculateTCP(){
	/*
	This function calculates PCP for the input fractionation and \shows the marker on TCP curve
	APA, 11/22/2020
	*/
	var fxsize = document.getElementById("fxsiz").value;
	var datevals = document.getElementById("txday").value;
	// var res = val1 + val2;
	//var txdays = val2.split(" ");
	var txDatesV = datevals.split(",");
	let txDaysV = new Array(txDatesV.length-1)
	var refDate = new Date(txDatesV[0])
	var dayFactor = 1000 * 3600 * 24
	for (var i = 0; i <= txDatesV.length-1; i++) {
	   var currDate = new Date(txDatesV[i])
	   txDaysV[i] = (currDate.getTime()-refDate.getTime())/ dayFactor + 1
   }
	tcp = Lung_TCP_Jeho(fxsize,txDaysV)
    //document.getElementById("tcp").innerHTML = "TCP = " + tcp[1];
    var data_update =  {
		x: [[tcp[0]]],
	    y: [[tcp[1]]]
	    }

    var layout_update = {
			title: {
    		text:'TCP = ' + Math.round(tcp[1] * 10000) / 10000.00,
    		 font: {
			      family: 'Courier New, monospace',
			      size: 32,
			      color: '#ff6961'
			    },
			    xref: 'paper',
    			x: 0.05
  			}
  		};

    Plotly.update('tcpPlotDiv', data_update, layout_update,[1])
    return;

};


function Lung_TCP_Jeho(fx_in,schedule_in) {
/* TCP model for stage-I lung cancer
Based on code by Jeho Jeong, jeongj@mskcc.org
AI 12/06/18 iyera@mskcc.org

INPUTS:
fx_in       : Fraction size in Gy (fx_in=2.5;)
schedule_in : Treatment schedule
E.g.: schedule_in=[ 1 ,2 ,3 ,4 ,5 ,8 ,9, 10, 11, 12, 15, 16, 17, 18, 19, 22, 23, 24, 25, 26, 29, 30, 31, 32, 33, 36, 37, 38, 39, 40];

*/

  // Define function f to calculate cell-cycle-dependent radiosensitivity
  // for different phases.
  function f(alpha_s, alpha_p, Alpha_ratio_p_cyc) {

    var F_p_cyc, a_over_b;
    F_p_cyc = [0.56, 0.24, 0.2]; // Cell cycle distribution (G1,S,G2+M phases)
    a_over_b = 2.8;

    out = F_p_cyc[0] * Math.exp(-Alpha_ratio_p_cyc[0] * alpha_s * 2 - Alpha_ratio_p_cyc[0] * (alpha_s / a_over_b) * 4) +
      F_p_cyc[1] * Math.exp(-alpha_s * 2 - (alpha_s / a_over_b) * 4) +
      F_p_cyc[2] * Math.exp(-Alpha_ratio_p_cyc[1] * alpha_s * 2 - Alpha_ratio_p_cyc[1] * (alpha_s / a_over_b) * 4) -
      Math.exp(-alpha_p * 2 - (alpha_p / a_over_b) * 4);

    return out;

  }


  // Variables for the analysis
  var alpha_p_ori, a_over_b, oer_i, rho_t, v_t_ref, f_s, t_c, f_p_pro_in, ht_loss, k_m, ht_lys;
  var oer_h, F_p_cyc, Alpha_ratio_p_cyc, d_t, clf_in, gf_in, beta_p_ori;

  alpha_p_ori = 0.305;
  a_over_b = 2.8;
  oer_i = 1.7;
  rho_t = 1e6;              // Tumor density (no. cells/mm^3)
  v_t_ref = 3e4;            // Ref. tumor volume (mm^3)
  f_s = 0.01;               // Stem cell fraction
  t_c = 2;                  // Cell cycle time (days)
  f_p_pro_in = 0.5;         // Fraction cells actively proliferating in p-compartment
  ht_loss = 2;              // Half-time of cell loss (h-compartment)
  k_m = 0.3;                // Survival probability of progeny after mitosis
  ht_lys = 3;               // Half-time for lysis

  oer_h = 1.37;                 // OER for h-compartment
  F_p_cyc = [0.56, 0.24, 0.2];  // Cell cycle distribution (G1,S,G2+M phases)
  Alpha_ratio_p_cyc = [2, 3];   // Relative alpha value for G1,S

  d_t = 15;                 // Simulation time (min)
  clf_in = 0.92;            // Cell loss factor
  gf_in = 0.25;             // Gross fraction

  beta_p_ori = alpha_p_ori / a_over_b;


  // EQD2 estimation for each cohort
  var EQD2, n_pt, v_t, alpha_p, beta_p, n_t, n_t_ref, total_clono_cell, delta_t, tstart;

  EQD2 = [];
  n_pt = [];

  v_t = 3e4;

  alpha_p = alpha_p_ori;
  beta_p = beta_p_ori;

  n_t = rho_t * v_t;                 //No. cells
  n_t_ref = rho_t * v_t_ref;
  total_clono_cell = n_t * f_s;
  delta_t = d_t / (60 * 24);         //dt in days
  t_start = 0;



  // Compartment size
  var IC, GF, TCP, TD50, BED, comp_size, comp_size_ref, p_pre, i_pre, h_pre, T_end, clf, gf;
  IC = [];
  GF = [];
  TCP = [];
  TD50 = [];
  BED = [];
  comp_size = [];       //P,H,I
  comp_size_ref = [];
  p_pre = [];
  i_pre = [];
  h_pre = [];
  T_end = [];


  clf = clf_in;
  gf = gf_in;


  // Run the sub-routine for a specific CLF and GF

  // For the initial st-st distribution:
  var f_p_pro = f_p_pro_in;

  comp_size[0] = gf / f_p_pro * n_t;
  comp_size[1] = (1 - gf * (1 / f_p_pro_in + clf * ht_loss / t_c)) * n_t;
  comp_size[2] = clf * gf * ht_loss / t_c * n_t;

  comp_size_ref[0] = gf / f_p_pro * n_t_ref;
  comp_size_ref[1] = (1 - gf * (1 / f_p_pro_in + clf * ht_loss / t_c)) * n_t_ref;
  comp_size_ref[2] = clf * gf * ht_loss / t_c * n_t_ref;


  // Record the the number of cells
  var f_p, f_i, f_h;
  var sum_comp_size = comp_size.reduce((a, b) => a + b, 0);
  f_p = comp_size[0] / sum_comp_size;
  f_i = comp_size[1] / sum_comp_size;
  f_h = comp_size[2] / sum_comp_size;


  var Treat_day, alpha_p, beta_p, alpha_i, beta_i, alpha_h, beta_h, f_p_pro, alpha_s, grid, pre_f;
  alpha_s = 0.3;
  grid = 0.1;
  pre_f = f(alpha_s, alpha_p, Alpha_ratio_p_cyc);

  while (Math.abs(f(alpha_s, alpha_p, Alpha_ratio_p_cyc)) >= Number.EPSILON) {
    if (pre_f * f(alpha_s, alpha_p, Alpha_ratio_p_cyc) < 0) {
      grid = grid * 0.1;
    }
    pre_f = f(alpha_s, alpha_p, Alpha_ratio_p_cyc);
    if (f(alpha_s, alpha_p, Alpha_ratio_p_cyc) > 0) {
      alpha_s = alpha_s + grid;
    } else {
      alpha_s = alpha_s - grid;
    }
  }

  var d, n, len;
  var fx_in_arr = [];
  if (Array.isArray(fx_in)) {
    fx_in_arr = fx_in;
    len = fx_in.length;
  } else {
    fx_in_arr[0] = fx_in;
    len = 1;
  }

  var Su_p, alpha_p_eff, beta_p_eff, Su_i_2gy, oer_i_g1, Su_h_2gy, oer_h_g1, p_d_pre, md, p_ex, i_ex;
  var p_def, i_def, p_ratio, i_ratio, h_ratio, s_sbrt, sf_sbrt, ntd2, d_sbrt, n_frac_sbrt, duration_sbrt, t_sbrt;
  var s_eqd2, s_eqd2_pre, sf_eqd2, sf_eqd2_pre, eqd2, eqd2_pre, add_time, cum_cell_dist;
  var cell_dist = [];
  var Alpha_p_cyc = [0, 0, 0];

  for (n = 0; n < len; n++) {

    d = fx_in_arr[n];
    Treat_day = schedule_in;

    // Cell cycle and dose-dependent radiosensitivity
    Alpha_p_cyc[1] = alpha_s;
    Alpha_p_cyc[0] = Alpha_p_cyc[1] * Alpha_ratio_p_cyc[0];
    Alpha_p_cyc[2] = Alpha_p_cyc[1] * Alpha_ratio_p_cyc[1];

    // Effective alpha, beta from survival fractions
    Su_p = F_p_cyc[0] * Math.exp(-Alpha_p_cyc[0] * d - (Alpha_p_cyc[0] / a_over_b) * Math.pow(d, 2)) +
      F_p_cyc[1] * Math.exp(-Alpha_p_cyc[1] * d - (Alpha_p_cyc[1] / a_over_b) * Math.pow(d, 2)) +
      F_p_cyc[2] * Math.exp(-Alpha_p_cyc[2] * d - (Alpha_p_cyc[2] / a_over_b) * Math.pow(d, 2));
    alpha_p_eff = -Math.log(Su_p) / (d * (1 + (d / a_over_b)));
    beta_p_eff = (alpha_p_eff / a_over_b);

    Su_i_2gy = Math.exp(-alpha_p / oer_i * 2 - (alpha_p / a_over_b) / Math.pow(oer_i, 2) * Math.pow(2, 2));
    oer_i_g1 = (-(Alpha_p_cyc[0] * 2) - Math.sqrt(Math.pow((Alpha_p_cyc[0] * 2), 2) -
      4 * Math.log(Su_i_2gy) * (Alpha_p_cyc[0] / a_over_b) * Math.pow(2, 2))) / (2 * Math.log(Su_i_2gy));
    Su_h_2gy = Math.exp(-alpha_p / oer_h * 2 - (alpha_p / a_over_b) / Math.pow(oer_h, 2) * Math.pow(2, 2));
    oer_h_g1 = (-(Alpha_p_cyc[0] * 2) - Math.sqrt(Math.pow(Alpha_p_cyc[0] * 2, 2) - 4 * Math.log(Su_h_2gy) * (Alpha_p_cyc[0] / a_over_b) * Math.pow(2, 2))) /
      (2 * Math.log(Su_h_2gy));
    alpha_i = Alpha_p_cyc[0] / oer_i_g1;
    beta_i = (Alpha_p_cyc[0] / a_over_b) / Math.pow(oer_i_g1, 2);
    alpha_h = Alpha_p_cyc[0] / oer_h_g1;
    beta_h = (Alpha_p_cyc[0] / a_over_b) / Math.pow(oer_h_g1, 2);

    alpha_p = alpha_p_eff;
    beta_p = beta_p_eff;

    // Run the sub-routine for a specific CLF and GF
    // RT fractional dose for SBRT schedule

    f_p_pro = f_p_pro_in; // Assign proliferating fraction to the initial value

    /* Cell distribution in each compartment
    (1:Pv, 2:Pd, 3:Iv, 4:Id, 5:Hv, 6:Hd, 7:lysis) (V:viable, D:doomed)
    Initially all compartments are fully filled with viable cells
    "comp_size" is the size of each compartment (1:P, 2:I, 3:H) */

    cell_dist[0] = comp_size[0];
    cell_dist[1] = 0;
    cell_dist[2] = comp_size[1];
    cell_dist[3] = 0;
    cell_dist[4] = comp_size[2];
    cell_dist[5] = 0;
    cell_dist[6] = 0;

    /* variables (t:time(day), j:# of fraction, add_time:additional time for
              weekend break, cum_cell_dist: cumulative cell distribution for
               each time increment) */
    var t = 0;
    var j = 0;
    var cum_cell_dist_sbrt = [];

    // Treat for specific SBRT schedule
    while (t < t_start + (Math.max(...Treat_day) - 1) + delta_t / 2)
    {
      // Change in f_p_pro (k_p) as blood supply improves
      f_p_pro = 1 - 0.5 * (cell_dist[0] + cell_dist[1]) / comp_size[0];

      // RT fraction
      if (t > (t_start + (Treat_day[j] - 1) - delta_t / 2) && t < (t_start + (Treat_day[j] - 1) + delta_t / 2)) {
        cell_dist[1] = cell_dist[1] + cell_dist[0] * (1 - Math.exp(-alpha_p * d - beta_p * Math.pow(d, 2)));
        cell_dist[0] = cell_dist[0] * Math.exp(-alpha_p * d - beta_p * Math.pow(d, 2));
        cell_dist[3] = cell_dist[3] + cell_dist[2] * (1 - Math.exp(-alpha_i * d - beta_i * Math.pow(d, 2)));
        cell_dist[2] = cell_dist[2] * Math.exp(-alpha_i * d - beta_i * Math.pow(d, 2));
        cell_dist[5] = cell_dist[5] + cell_dist[4] * (1 - Math.exp(-alpha_h * d - beta_h * Math.pow(d, 2)));
        cell_dist[4] = cell_dist[4] * Math.exp(-alpha_h * d - beta_h * Math.pow(d, 2));

        j = j + 1;
      }

      // Cell Proliferation & Death
      cell_dist[0] = cell_dist[0] * Math.pow(2, (f_p_pro * delta_t / t_c));
      h_pre = cell_dist[4] + cell_dist[5];
      cell_dist[4] = cell_dist[4] * Math.pow(0.5, (delta_t / ht_loss));
      cell_dist[5] = cell_dist[5] * Math.pow(0.5, (delta_t / ht_loss));
      p_d_pre = cell_dist[1];
      cell_dist[1] = cell_dist[1] * Math.pow(2, (f_p_pro * (2 * k_m - 1) * delta_t / t_c));

      // Mitotically dead cell in 1 time step
      md = p_d_pre - cell_dist[1] + (h_pre - cell_dist[4] - cell_dist[5]);
      cell_dist[6] = cell_dist[6] + md;
      cell_dist[6] = cell_dist[6] * Math.pow(0.5, (delta_t / ht_lys));

      // Recompartmentalization of the cell
      if (cell_dist[0] + cell_dist[1] >= comp_size[0]) {
        p_ex = (cell_dist[0] + cell_dist[1]) - comp_size[0];
        p_ratio = cell_dist[0] / (cell_dist[0] + cell_dist[1]);
        cell_dist[0] = comp_size[0] * p_ratio;
        cell_dist[1] = comp_size[0] * (1 - p_ratio);
        cell_dist[2] = cell_dist[2] + p_ex * p_ratio;
        cell_dist[3] = cell_dist[3] + p_ex * (1 - p_ratio);
      } else {
        if (cell_dist[2] + cell_dist[3] > 0) {
          if (cell_dist[2] + cell_dist[3] > comp_size[0] - (cell_dist[0] + cell_dist[1])) {
            p_def = comp_size[0] - (cell_dist[0] + cell_dist[1]);
            i_ratio = cell_dist[2] / (cell_dist[2] + cell_dist[3]);
            cell_dist[0] = cell_dist[0] + p_def * i_ratio;
            cell_dist[1] = cell_dist[1] + p_def * (1 - i_ratio);
            cell_dist[2] = cell_dist[2] - p_def * i_ratio;
            cell_dist[3] = cell_dist[3] - p_def * (1 - i_ratio);
          } else {
            cell_dist[0] = cell_dist[0] + cell_dist[2];
            cell_dist[1] = cell_dist[1] + cell_dist[3];
            cell_dist[2] = 0;
            cell_dist[3] = 0;
            if (cell_dist[4] + cell_dist[5] > 0) {
              if (cell_dist[4] + cell_dist[5] > comp_size[0] - (cell_dist[0] + cell_dist[1])) {
                p_def = comp_size[0] - (cell_dist[0] + cell_dist[1]);
                h_ratio = cell_dist[4] / (cell_dist[4] + cell_dist[5]);
                cell_dist[0] = cell_dist[0] + p_def * h_ratio;
                cell_dist[1] = cell_dist[1] + p_def * (1 - h_ratio);
                cell_dist[4] = cell_dist[4] - p_def * h_ratio;
                cell_dist[5] = cell_dist[5] - p_def * (1 - h_ratio);
              } else {
                cell_dist[0] = cell_dist[0] + cell_dist[4];
                cell_dist[1] = cell_dist[1] + cell_dist[5];
                cell_dist[4] = 0;
                cell_dist[5] = 0;
              }
            }
          }
        }
      }

      if (cell_dist[2] + cell_dist[3] >= comp_size[1]) {
        i_ex = (cell_dist[2] + cell_dist[3]) - comp_size[1];
        i_ratio = cell_dist[2] / (cell_dist[2] + cell_dist[3]);
        cell_dist[2] = comp_size[1] * i_ratio;
        cell_dist[3] = comp_size[1] * (1 - i_ratio);
        cell_dist[4] = cell_dist[4] + i_ex * i_ratio;
        cell_dist[5] = cell_dist[5] + i_ex * (1 - i_ratio);
      } else {
        if (cell_dist[4] + cell_dist[5] > 0) {
          if (cell_dist[4] + cell_dist[5] > comp_size[1] - (cell_dist[2] + cell_dist[3])) {
            i_def = comp_size[1] - (cell_dist[2] + cell_dist[3]);
            h_ratio = cell_dist[4] / (cell_dist[4] + cell_dist[5]);
            cell_dist[2] = cell_dist[2] + i_def * h_ratio;
            cell_dist[3] = cell_dist[3] + i_def * (1 - h_ratio);
            cell_dist[4] = cell_dist[4] - i_def * h_ratio;
            cell_dist[5] = cell_dist[5] - i_def * (1 - h_ratio);
          } else {
            cell_dist[2] = cell_dist[2] + cell_dist[4];
            cell_dist[3] = cell_dist[3] + cell_dist[5];
            cell_dist[4] = 0;
            cell_dist[5] = 0;
          }
        }
      }


      // Time step increase and store the number of cells in each compartment
      t = t + delta_t;
      cum_cell_dist_sbrt = cum_cell_dist_sbrt.concat(cell_dist);

    }

    s_sbrt = cell_dist[0] + cell_dist[2] + cell_dist[4];                        //Cell survival
    sf_sbrt = s_sbrt / sum_comp_size;                                           //Survival fraction
    ntd2 = Treat_day.length * d * (1 + (d / a_over_b)) / (1 + (2 / a_over_b));  //2Gy equivalent dose
    d_sbrt = d;
    n_frac_sbrt = Treat_day.length;
    duration_sbrt = Math.max.apply(null, Treat_day)
    t_sbrt = t;


    // For EQD2 calculation
    d = 2;
    alpha_p = alpha_p_ori;
    beta_p = beta_p_ori;
    alpha_i = alpha_p_ori / oer_i;
    beta_i = beta_p_ori / Math.pow(oer_i, 2);
    alpha_h = alpha_p_ori / oer_h;
    beta_h = beta_p_ori / Math.pow(oer_h, 2);
    s_eqd2 = 0;
    sf_eqd2 = 0;
    eqd2 = 0;


    // RT fractional dose for EQD2 estimation

    // Assign proliferating fraction to the initial value

    f_p_pro = f_p_pro_in;

    /* Cell distribution in each compartment
     (1:Pv, 2:Pd, 3:Iv, 4:Id, 5:Hv, 6:Hd, 7:lysis)
     Initially all compartments are fully filled with viable cells
     "comp_size" is the size of each compartment (1:P, 2:I, 3:H) */

    cell_dist = [];
    cell_dist[0] = comp_size_ref[0];
    cell_dist[1] = 0;
    cell_dist[2] = comp_size_ref[1];
    cell_dist[3] = 0;
    cell_dist[4] = comp_size_ref[2];
    cell_dist[5] = 0;
    cell_dist[6] = 0;


    /* variables (t:time(day), j:# of fraction, add_time:additional time for
               weekend break, cum_cell_dist: cumulative cell distribution for
             each time increment) */
    t = 0;
    j = 0;
    add_time = 0;
    cum_cell_dist = [];

    // Treat until the SF becomes equivalent to SBRT regime
    while ((cell_dist[0] + cell_dist[2] + cell_dist[4]) > s_sbrt) {
      // Change in f_p_pro (k_p) as blood supply improves
      f_p_pro = 1 - 0.5 * (cell_dist[0] + cell_dist[1]) / comp_size[0];


      // RT fraction
      if (t > (t_start + j + add_time - delta_t / 2) && t < (t_start + j + add_time + delta_t / 2)) {
        cell_dist[1] = cell_dist[1] + cell_dist[0] * (1 - Math.exp(-alpha_p * d - beta_p * Math.pow(d, 2)));
        cell_dist[0] = cell_dist[0] * Math.exp(-alpha_p * d - beta_p * Math.pow(d, 2));
        cell_dist[3] = cell_dist[3] + cell_dist[2] * (1 - Math.exp(-alpha_i * d - beta_i * Math.pow(d, 2)));
        cell_dist[2] = cell_dist[2] * Math.exp(-alpha_i * d - beta_i * Math.pow(d, 2));
        cell_dist[5] = cell_dist[5] + cell_dist[4] * (1 - Math.exp(-alpha_h * d - beta_h * Math.pow(d, 2)));
        cell_dist[4] = cell_dist[4] * Math.exp(-alpha_h * d - beta_h * Math.pow(d, 2));

        j = j + 1;

        //Week-end break
        if (j % 5 == 0) {
          add_time = add_time + 2;
        }
      }


      //Cell Proliferation & Death
      cell_dist[0] = cell_dist[0] * Math.pow(2, (f_p_pro * delta_t / t_c));
      h_pre = cell_dist[4] + cell_dist[5];
      cell_dist[4] = cell_dist[4] * Math.pow(0.5, (delta_t / ht_loss));
      cell_dist[5] = cell_dist[5] * Math.pow(0.5, (delta_t / ht_loss));
      p_d_pre = cell_dist[1];
      cell_dist[1] = cell_dist[1] * Math.pow(2, (f_p_pro * (2 * k_m - 1) * delta_t / t_c));


      //Mitotically dead cell in 1 time step
      md = p_d_pre - cell_dist[1] + (h_pre - cell_dist[4] - cell_dist[5]);
      cell_dist[6] = cell_dist[6] + md;
      cell_dist[6] = cell_dist[6] * Math.pow(0.5, (delta_t / ht_lys));


      //Recompartmentalization of the cell
      if (cell_dist[0] + cell_dist[1] >= comp_size[0]) {
        p_ex = (cell_dist[0] + cell_dist[1]) - comp_size[0];
        p_ratio = cell_dist[0] / (cell_dist[0] + cell_dist[1]);
        cell_dist[0] = comp_size[0] * p_ratio;
        cell_dist[1] = comp_size[0] * (1 - p_ratio);
        cell_dist[2] = cell_dist[2] + p_ex * p_ratio;
        cell_dist[3] = cell_dist[3] + p_ex * (1 - p_ratio);
      } else {
        if (cell_dist[2] + cell_dist[3] > 0) {
          if (cell_dist[2] + cell_dist[3] > comp_size[0] - (cell_dist[0] + cell_dist[1])) {
            p_def = comp_size[0] - (cell_dist[0] + cell_dist[1]);
            i_ratio = cell_dist[2] / (cell_dist[2] + cell_dist[3]);
            cell_dist[0] = cell_dist[0] + p_def * i_ratio;
            cell_dist[1] = cell_dist[1] + p_def * (1 - i_ratio);
            cell_dist[2] = cell_dist[2] - p_def * i_ratio;
            cell_dist[3] = cell_dist[3] - p_def * (1 - i_ratio);
          } else {
            cell_dist[0] = cell_dist[0] + cell_dist[2];
            cell_dist[1] = cell_dist[1] + cell_dist[3];
            cell_dist[2] = 0;
            cell_dist[3] = 0;
            if (cell_dist[4] + cell_dist[5] > 0) {
              if (cell_dist[4] + cell_dist[5] > comp_size[0] - (cell_dist[0] + cell_dist[1])) {
                p_def = comp_size[0] - (cell_dist[0] + cell_dist[1]);
                h_ratio = cell_dist[4] / (cell_dist[4] + cell_dist[5]);
                cell_dist[0] = cell_dist[0] + p_def * h_ratio;
                cell_dist[1] = cell_dist[1] + p_def * (1 - h_ratio);
                cell_dist[4] = cell_dist[4] - p_def * h_ratio;
                cell_dist[5] = cell_dist[5] - p_def * (1 - h_ratio);
              } else {
                cell_dist[0] = cell_dist[0] + cell_dist[4];
                cell_dist[1] = cell_dist[1] + cell_dist[5];
                cell_dist[4] = 0;
                cell_dist[5] = 0;
              }
            }
          }
        }
      }


      if (cell_dist[2] + cell_dist[3] >= comp_size[1]) {
        i_ex = (cell_dist[2] + cell_dist[3]) - comp_size[1];
        i_ratio = cell_dist[2] / (cell_dist[2] + cell_dist[3]);
        cell_dist[2] = comp_size[1] * i_ratio;
        cell_dist[3] = comp_size[1] * (1 - i_ratio);
        cell_dist[4] = cell_dist[4] + i_ex * i_ratio;
        cell_dist[5] = cell_dist[5] + i_ex * (1 - i_ratio);
      } else {
        if (cell_dist[4] + cell_dist[5] > 0) {
          if (cell_dist[4] + cell_dist[5] > comp_size[1] - (cell_dist[2] + cell_dist[3])) {
            i_def = comp_size[1] - (cell_dist[2] + cell_dist[3]);
            h_ratio = cell_dist[4] / (cell_dist[4] + cell_dist[5]);
            cell_dist[2] = cell_dist[2] + i_def * h_ratio;
            cell_dist[3] = cell_dist[3] + i_def * (1 - h_ratio);
            cell_dist[4] = cell_dist[4] - i_def * h_ratio;
            cell_dist[5] = cell_dist[5] - i_def * (1 - h_ratio);
          } else {
            cell_dist[2] = cell_dist[2] + cell_dist[4];
            cell_dist[3] = cell_dist[3] + cell_dist[5];
            cell_dist[4] = 0;
            cell_dist[5] = 0;
          }
        }
      }



      // time step increase and store the number of cells in each compartment
      t = t + delta_t;
      cum_cell_dist = cum_cell_dist.concat(cell_dist);

      s_eqd2_pre = s_eqd2;
      sf_eqd2_pre = sf_eqd2;
      eqd2_pre = eqd2;

      s_eqd2 = cell_dist[0] + cell_dist[2] + cell_dist[4];
      sf_eqd2 = s_eqd2 / sum_comp_size;
      tcp = Math.exp(-s_eqd2 * f_s);
      eqd2 = j * d;

    }

    eqd2 = eqd2_pre + ((eqd2 - eqd2_pre) / (s_eqd2_pre - s_eqd2)) * (s_eqd2_pre - s_sbrt);
  }

  var TD_50 = 62.1;
  var gamma_50 = 1.5;
  var TCP_upper_bound = 0.95;

  TCP = TCP_upper_bound / (1 + Math.pow(TD_50 / eqd2, 4 * gamma_50));

  return [eqd2, TCP];

};


// APA commented to get rid of missing module error
// Export module for testing
//module.exports = function(fx_in,schedule_in) {
//  var myModule = Lung_TCP_Jeho(fx_in,schedule_in);
//  return myModule;
//};
