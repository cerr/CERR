/*
  This code was adapted from https://github.com/praneetnadkar/multidatepicker
  APA, 11/22/2020
*/

var today = new Date();
var currentMonth = today.getMonth();
var currentYear = today.getFullYear();
var selectYear = document.getElementById("year");
var selectMonth = document.getElementById("month");

var months = [];
var selectedDates = [];
var years = [];

// parameters to be set for the datepicker to run accordingly
var minYear = 2011;
var maxYear = 2020;
var startMonth = 0;
var endMonth = 11;
var highlightToday = true;
var dateSeparator = ', ';

// constants that would be used in the script
const dictionaryMonth =
    [
        ["Jan", 0],
        ["Feb", 1],
        ["Mar", 2],
        ["Apr", 3],
        ["May", 4],
        ["Jun", 5],
        ["Jul", 6],
        ["Aug", 7],
        ["Sep", 8],
        ["Oct", 9],
        ["Nov", 10],
        ["Dec", 11]
    ];

//this class will add a background to the selected date
const highlightClass = 'highlight';

$(document).ready(function (e) {
    today = new Date();
    currentMonth = today.getMonth();
    currentYear = today.getFullYear();
    selectYear = document.getElementById("year");
    selectMonth = document.getElementById("month");
    loadControl(currentMonth, currentYear);
});

function next() {
    currentYear = currentMonth === 11 ? currentYear + 1 : currentYear;
    currentMonth = currentMonth + 1 % 12;
    loadControl(currentMonth, currentYear);
}

function previous() {
    currentYear = currentMonth === 0 ? currentYear - 1 : currentYear;
    currentMonth = currentMonth === 0 ? 11 : currentMonth - 1;
    loadControl(currentMonth, currentYear);
}

function change() {
    currentYear = parseInt(selectYear.value);
    currentMonth = parseInt(selectMonth.value);
    loadControl(currentMonth, currentYear);
}


function loadControl(month, year) {

    addMonths(month);
    addYears(year);

    let firstDay = (new Date(year, month)).getDay();

     // body of the calendar
    var tbl = document.querySelector("#calendar-body");
    // clearing all previous cells
    tbl.innerHTML = "";


    var monthAndYear = document.getElementById("monthAndYear");
    // filing data about month and in the page via DOM.
    monthAndYear.innerHTML = months[month] + " " + year;


    selectYear.value = year;
    selectMonth.value = month;

    // creating the date cells here
    let date = 1;

    // add the selected dates here to preselect
    //selectedDates.push((month + 1).toString() + '/' + date.toString() + '/' + year.toString());

    // there will be maximum 6 rows for any month
    for (let rowIterator = 0; rowIterator < 6; rowIterator++) {

        // creates a new table row and adds it to the table body
        let row = document.createElement("tr");

        //creating individual cells, filing them up with data.
        for (let cellIterated = 0; cellIterated < 7 && date <= daysInMonth(month, year); cellIterated++) {

            // create a table data cell
            cell = document.createElement("td");
            let textNode = "";

            // check if this is the valid date for the month
            if (rowIterator !== 0 || cellIterated >= firstDay) {
                cell.id = (month + 1).toString() + '/' + date.toString() + '/' + year.toString();
                cell.class = "clickable";
                textNode = date;

                // this means that highlightToday is set to true and the date being iterated it todays date,
                // in such a scenario we will give it a background color
                if (highlightToday
                    && date === today.getDate() && year === today.getFullYear() && month === today.getMonth()) {
                    cell.classList.add("today-color");
                }

                // set the previous dates to be selected
                // if the selectedDates array has the dates, it means they were selected earlier.
                // add the background to it.
                if (selectedDates.indexOf((month + 1).toString() + '/' + date.toString() + '/' + year.toString()) >= 0) {
                    cell.classList.add(highlightClass);
                }

                date++;
            }

            cellText = document.createTextNode(textNode);
            cell.appendChild(cellText);
            row.appendChild(cell);
        }

        tbl.appendChild(row); // appending each row into calendar body.
    }

    // this adds the button panel at the bottom of the calendar
    addButtonPanel(tbl);

    // function when the date cells are clicked
    $("#calendar-body tr td").click(function (e) {
        var id = $(this).attr('id');
        // check the if cell clicked has a date
        // those with an id, have the date
        if (typeof id !== typeof undefined) {
            var classes = $(this).attr('class');
            if (typeof classes === typeof undefined || !classes.includes(highlightClass)) {
                var selectedDate = new Date(id);
                selectedDates.push((selectedDate.getMonth() + 1).toString() + '/' + selectedDate.getDate().toString() + '/' + selectedDate.getFullYear());
            }
            else {
                var index = selectedDates.indexOf(id);
                if (index > -1) {
                    selectedDates.splice(index, 1);
                }
            }

            $(this).toggleClass(highlightClass);
        }

        // sort the selected dates array based on the latest date first
        var sortedArray = selectedDates.sort((a, b) => {
            return new Date(a) - new Date(b);
        });

        // update the txday text input
        document.getElementById('txday').value = datesToString(sortedArray);
    });


    var $search = $('#txday');
    var $dropBox = $('#txdayparent');

    $search.on('blur', function (event) {
        //$dropBox.hide();
    }).on('focus', function () {
        $dropBox.show();
    });
}


// check how many days in a month code from https://dzone.com/articles/determining-number-days-month
function daysInMonth(iMonth, iYear) {
    return 32 - new Date(iYear, iMonth, 32).getDate();
}

// adds the months to the dropdown
function addMonths(selectedMonth) {
    var select = document.getElementById("month");

    if (months.length > 0) {
        return;
    }

    for (var month = startMonth; month <= endMonth; month++) {
        var monthInstance = dictionaryMonth[month];
        months.push(monthInstance[0]);
        select.options[select.options.length] = new Option(monthInstance[0], monthInstance[1], parseInt(monthInstance[1]) === parseInt(selectedMonth));
    }
}

// adds the years to the selection dropdown
// by default it is from 1990 to 2030
function addYears(selectedYear) {

    if (years.length > 0) {
        return;
    }

    var select = document.getElementById("year");

    for (var year = minYear; year <= maxYear; year++) {
        years.push(year);
        select.options[select.options.length] = new Option(year, year, parseInt(year) === parseInt(selectedYear));
    }
}

resetCalendar = function resetCalendar() {
    // reset all the selected dates
    selectedDates = [];
    $('#calendar-body tr').each(function () {
        $(this).find('td').each(function () {
            // $(this) will be the current cell
            $(this).removeClass(highlightClass);
        });
    });
};

function datesToString(dates) {
    return dates.join(dateSeparator);
}

function endSelection() {
    $('#txdayparent').hide();
}


// to add the button panel at the bottom of the calendar
function addButtonPanel(tbl) {
    // after we have looped for all the days and the calendar is complete,
    // we will add a panel that will show the buttons, reset and done
    let row = document.createElement("tr");
    row.className = 'buttonPanel';
    cell = document.createElement("td");
    cell.colSpan = 7;
    var parentDiv = document.createElement("div");
    parentDiv.classList.add('row');
    parentDiv.classList.add('buttonPanel-row');


    var div = document.createElement("div");
    div.className = 'col-sm';
    var resetButton = document.createElement("button");
    resetButton.className = 'btn';
    resetButton.value = 'Reset';
    resetButton.onclick = function () { resetCalendar(); };
    var resetButtonText = document.createTextNode("Reset");
    resetButton.appendChild(resetButtonText);

    div.appendChild(resetButton);
    parentDiv.appendChild(div);


    var div2 = document.createElement("div");
    div2.className = 'col-sm';
    var doneButton = document.createElement("button");
    doneButton.className = 'btn';
    doneButton.value = 'Done';
    doneButton.onclick = function () { endSelection(); };
    var doneButtonText = document.createTextNode("Done");
    doneButton.appendChild(doneButtonText);

    div2.appendChild(doneButton);
    parentDiv.appendChild(div2);

    cell.appendChild(parentDiv);
    row.appendChild(cell);
    // appending each row into calendar body.
    tbl.appendChild(row);
}
