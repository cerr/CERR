/*Tests for Lung_TCP_Jeho
  AI 12/06/18 iyera@mskcc.org
*/

let fn = require('./Lung_TCP_Jeho.js');

//Expected ouputs
var expectedEQD_test1 = 293.16520741963905;
var expectedTCP_test1 = 0.9499141857501763;
var expectedEQD_test2 = 40;
var expectedTCP_test2 = .06332494720363897;
var tol = 1e-5;
var diff1, diff2;

// Test case-1  
var fx_in = 5;
var schedule_in = [1, 2, 3, 4, 5, 8, 9, 10, 11, 12, 15, 16, 17, 18, 19, 22, 23, 24, 25, 26, 29, 30, 31, 32, 33, 36, 37, 38, 39, 40];
var out = fn(fx_in,schedule_in);
diff1 = Math.abs(expectedEQD_test1-out[0]);
diff2 = Math.abs(expectedTCP_test1-out[1]);
if (diff1<tol && diff2<tol){
  console.log('Passed test-1.')
}else{
  console.log('Error: Test1 failed!')
}

// Test case-2
fx_in = 2;
schedule_in = [1, 2, 3, 4, 5, 8, 9, 10, 11, 12, 15, 16, 17, 18, 19, 22, 23, 24, 25, 26];
out = fn(fx_in,schedule_in);
diff1 = Math.abs(expectedEQD_test2-out[0]);
diff2 = Math.abs(expectedTCP_test2-out[1]);
if (diff1<tol && diff2<tol){
  console.log('Passed test-2.')
}else{
  console.log('Error: Test1 failed!')
}