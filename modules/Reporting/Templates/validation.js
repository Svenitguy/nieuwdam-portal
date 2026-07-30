/* ==========================================================
   Nieuwdam Validation Dashboard
   JavaScript Engine v5.0

   Features:
   - Microsoft Graph validation reporting
   - JSON loading
   - Dashboard statistics
   - Filtering
   - Pagination
   - Dark mode
   - Fluent UI support

========================================================== */


/* ==========================================================
   GLOBAL STATE
========================================================== */


let results = [];

let filteredResults = [];

let currentPage = 1;

let pageSize = 25;

let reportMetadata = {};

/* ==========================================================
   APPLICATION START
========================================================== */


document.addEventListener(
    "DOMContentLoaded",
    () => {


        loadReport();


        initializeTheme();


        initializePaginationControls();


        initializePageSizeControl();


    }
);

function initializePaginationControls() {

    const nextButton =
        document.getElementById("nextPage");

    const previousButton =
        document.getElementById("previousPage");


    if (nextButton) {

        nextButton.addEventListener(
            "click",
            () => {

                if (currentPage < getTotalPages()) {

                    currentPage++;

                    renderPage();

                }

            }
        );

    }



    if (previousButton) {

        previousButton.addEventListener(
            "click",
            () => {

                if (currentPage > 1) {

                    currentPage--;

                    renderPage();

                }

            }
        );

    }


}





/* ==========================================================
   LOAD JSON REPORT
========================================================== */


async function loadReport() {


    try {


        const response =
            await fetch(reportFile);



        if (!response.ok) {


            throw new Error(
                "Report could not be loaded"
            );


        }



const data =
    await response.json();



if (!data.Results || !Array.isArray(data.Results)) {


    throw new Error(
        "Invalid report format"
    );


}



results =
    data.Results;


filteredResults =
    data.Results;

reportMetadata = data;

updateRunInformation(data);


        initializeDashboard();



    }


    catch (error) {


        console.error(
            "Report loading failed:",
            error
        );



        showLoadError(error);


    }


}





/* ==========================================================
   DASHBOARD INITIALIZATION
========================================================== */


function initializeDashboard() {


    updateDashboard(
        filteredResults
    );


    renderPage();


    updateRunInformation(reportMetadata);


    initializeFilters();

}







/* ==========================================================
   COMPLETE DASHBOARD UPDATE
========================================================== */


function updateDashboard(data) {


    updateCards(data);


    updateSummary(data);


    updateFailures(data);

}







/* ==========================================================
   KPI CARDS
========================================================== */


function updateCards(data) {


    const total =
        data.length;



    const passed =
        data.filter(
            item =>
                item.Status === "PASS"
        )
            .length;



    const failed =
        data.filter(
            item =>
                item.Status === "FAIL"
        )
            .length;



    const successRate =


        total === 0

            ? 0

            :

            Math.round(
                (
                    passed /
                    total
                )
                *
                100
            );



    setText(
        "totalChecks",
        total
    );


    setText(
        "passedChecks",
        passed
    );


    setText(
        "failedChecks",
        failed
    );


    setText(
        "successRate",
        successRate + "%"
    );



    const progress =
        document.getElementById(
            "progressBar"
        );



    if (progress) {


        progress.style.width =
            successRate + "%";

        setText(
            "progressPercentage",
            successRate + "%"
        );

    }


}







/* ==========================================================
   SUMMARY
========================================================== */


function updateSummary(data) {


    const summary =
        document.getElementById(
            "summary"
        );



    if (!summary) {


        return;


    }



    const passed =
        data.filter(
            item =>
                item.Status === "PASS"
        )
            .length;



    const failed =
        data.filter(
            item =>
                item.Status === "FAIL"
        )
            .length;



    summary.innerHTML = `


        <p>
            Total checks:
            <strong>
                ${data.length}
            </strong>
        </p>


        <p>
            Successful:
            <strong class="pass">
                ${passed}
            </strong>
        </p>


        <p>
            Failed:
            <strong class="fail">
                ${failed}
            </strong>
        </p>


    `;


}







/* ==========================================================
   RECENT FAILURES
========================================================== */


function updateFailures(data) {


    const container =
        document.getElementById(
            "recentFailures"
        );



    if (!container) {


        return;


    }



    const failures =

        data.filter(
            item =>
                item.Status === "FAIL"
        )
            .slice(
                0,
                5
            );



    if (failures.length === 0) {


        container.innerHTML = `

            <span class="pass">
                No failures detected
            </span>

        `;


        return;


    }



    container.innerHTML =

        failures
            .map(
                item => `

                <div class="failure-item">

                    <strong>
                        ${escapeHtml(item.Name)}
                    </strong>

                    <br>

                    <span>
                        ${escapeHtml(item.Message)}
                    </span>

                </div>

            `
            )
            .join("");


}


/* ==========================================================
   TABLE RENDER ENGINE
========================================================== */


function render(data) {


    const table =
        document.getElementById("results");


    if (!table) {

        return;

    }


    table.innerHTML = "";


    if (!data || data.length === 0) {


        table.innerHTML = `

<tr>

    <td colspan="7">

        <div class="empty-state">

            No results found

        </div>

    </td>

</tr>

`;


        updatePagination([]);

        return;

    }



    data.forEach(item => {



        const row =
            document.createElement("tr");



        if (item.Status === "FAIL") {

            row.classList.add("fail-row");

        }


        if (item.Status === "PASS") {

            row.classList.add("pass-row");

        }

        if (item.Status === "WARNING") {

            row.classList.add("warning-row");

        }


        row.innerHTML = `

    <td>
        ${item.Type ?? ""}
    </td>

    <td>
        ${item.Name ?? ""}
    </td>

    <td>
        ${item.Check ?? ""}
    </td>

<td>

    <span class="status ${(item.Status || "").toLowerCase()}">

        ${item.Status === "PASS"
                ? "✔ PASS"
                : item.Status === "FAIL"
                    ? "✖ FAIL"
                    : item.Status === "WARNING"
                        ? "⚠ WARNING"
                        : item.Status ?? ""
            }

    </span>

</td>

    <td>
        ${item.Expected ?? ""}
    </td>

    <td>
        ${item.Actual ?? ""}
    </td>

    <td>
        ${item.Message ?? ""}
    </td>

`;



        table.appendChild(row);



    });



    updatePagination(filteredResults);

}





/* ==========================================================
   PAGINATION
========================================================== */


function updatePagination(data) {


    const count =
        document.getElementById(
            "resultCount"
        );



    if (count) {


        count.innerText =
            `${data.length} results`;


    }




    const pageInfo =
        document.getElementById(
            "pageInfo"
        );



    if (!pageInfo) {

        return;

    }




    if (pageSize === "ALL") {


        pageInfo.innerText =
            "All results";


        return;


    }




    const totalPages =
        Math.max(
            1,
            Math.ceil(
                data.length / pageSize
            )
        );



    pageInfo.innerText =

        `Page ${currentPage} / ${totalPages}`;



}





function getTotalPages() {


    if (pageSize === "ALL") {


        return 1;


    }



    return Math.max(

        1,

        Math.ceil(
            filteredResults.length /
            pageSize
        )

    );


}





function renderPage() {

    let pageData = filteredResults;

    if (pageSize !== "ALL") {

        const size = Number(pageSize);

        const start = (currentPage - 1) * size;

        pageData = filteredResults.slice(
            start,
            start + size
        );

    }

    render(pageData);

}





function updatePageInfo() {


    const element =
        document.getElementById(
            "pageInfo"
        );



    if (!element) {

        return;

    }




    if (pageSize === "ALL") {


        element.innerText =
            "All results";


        return;

    }




    element.innerText =

        `Page ${currentPage}/${getTotalPages()}`;



}


/* ==========================================================
   SAFE VALUE HELPER
========================================================== */


function safe(value) {


    if (
        value === null ||
        value === undefined ||
        value === ""
    ) {


        return "-";


    }



    return value;


}







/* ==========================================================
   STATUS HELPERS
========================================================== */


function countStatus(data, status) {


    return data.filter(
        item =>
            item.Status === status
    )
        .length;


}





function calculateSuccess(data) {


    if (!data || data.length === 0) {


        return 0;


    }



    const passed =
        countStatus(
            data,
            "PASS"
        );



    return Math.round(

        (
            passed /
            data.length

        )
        *
        100

    );


}







/* ==========================================================
   DASHBOARD REFRESH
========================================================== */


function refreshDashboard() {


    updateDashboard(
        filteredResults
    );


    renderPage();


}






/* ==========================================================
   AUTO REFRESH SUPPORT
========================================================== */


let refreshTimer = null;




function startAutoRefresh(minutes = 5) {



    stopAutoRefresh();




    refreshTimer =

        setInterval(
            () => {


                loadReport();



            },

            minutes * 60 * 1000

        );



}






function stopAutoRefresh() {


    if (refreshTimer) {


        clearInterval(
            refreshTimer
        );


        refreshTimer = null;


    }


}





/* ==========================================================
   ERROR HANDLING
========================================================== */


function showError(message) {


    const summary =
        document.getElementById(
            "summary"
        );



    if (!summary) {

        return;

    }



    summary.innerHTML = `


        <div class="failure-item">


            <strong>
                Error
            </strong>


            <br>


            <span>
                ${message}
            </span>


        </div>


    `;


}







/* ==========================================================
   EXPORT CSV
========================================================== */


function exportCSV() {


    if (
        !filteredResults ||
        filteredResults.length === 0
    ) {


        return;


    }



    const headers =

        [
            "RunId",
            ...Object.keys(filteredResults[0])
        ];



    const rows =

        filteredResults.map(
            item =>

                headers.map(
                    h => {

                        if (h === "RunId") {

                            return `"${reportMetadata.RunId}"`;

                        }

                        return `"${item[h] ?? ""}"`;

                    }
                )
                .join(",")

        );



    const csv =

        [
            headers.join(","),
            ...rows

        ]
            .join("\n");



    const blob =

        new Blob(
            [
                csv
            ],
            {
                type:
                    "text/csv"
            }
        );



    const url =

        URL.createObjectURL(
            blob
        );



    const link =
        document.createElement(
            "a"
        );



    link.href = url;


    link.download =
        "validation-report.csv";



    link.click();



    URL.revokeObjectURL(
        url
    );


}


function initializePageSizeControl() {

    const pageSizeSelect =
        document.getElementById("pageSize");


    if (pageSizeSelect) {

        pageSizeSelect.addEventListener(
            "change",
            () => {


                if (pageSizeSelect.value === "ALL") {

                    pageSize = "ALL";

                }
                else {

                    pageSize =
                        Number(pageSizeSelect.value);

                }


                currentPage = 1;

                renderPage();


            }
        );

    }

}

function setText(id, value) {

    const element =
        document.getElementById(id);


    if (element) {

        element.innerText = value;

    }

}

function showLoadError(error) {

    console.error(
        "Report loading failed:",
        error
    );


    const summary =
        document.getElementById("summary");


    if (summary) {

        summary.innerHTML =
            `
        <span class="fail">
            Failed loading report
        </span>
        `;

    }

}

function escapeHtml(value) {

    if (value === null || value === undefined) {

        return "";

    }


    return String(value)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;");

}


/*function updateMetadata(data) {


    const generated =
        document.getElementById("generatedDate");


    const runId =
        document.getElementById("runId");



    if (runId) {

        runId.innerText =
            reportInfo.runId || "Unknown";

    }



    if (!generated) {

        return;

    }


    if (
        data &&
        data.length > 0 &&
        data[0].Timestamp
    ) {


        let timestamp =
            data[0].Timestamp;


        if (
            typeof timestamp === "object" &&
            timestamp.value
        ) {

            timestamp =
                timestamp.value;

        }


        const date =
            new Date(timestamp);


        generated.innerText =
            isNaN(date)
                ? timestamp
                : date.toLocaleString("nl-BE");


    }

}*/

function updateRunInformation(data) {

    if (!data) {
        return;
    }


    const runId =
        document.getElementById("runId");


    if (runId) {

        runId.innerText =
            data.RunId ?? "Unknown";

    }


    const generated =
        document.getElementById("generatedDate");


    if (!generated) {

        return;

    }


    if (data.Generated) {


        // Nieuwe JSON structuur:
        // Generated = { value: "/Date(1784656925506)/", DateTime: "..." }

        if (
            typeof data.Generated === "object" &&
            data.Generated.value
        ) {


            const match =
                data.Generated.value.match(/\d+/);


            if (match) {


                const date =
                    new Date(
                        Number(match[0])
                    );


                generated.innerText =
                    date.toLocaleString(
                        "nl-BE"
                    );


                return;

            }


        }


        // Fallback indien Generated ooit gewoon tekst is

        generated.innerText =
            data.Generated;


    }

}

function initializeFilters() {

    const searchBox =
        document.getElementById("search");


    const statusFilter =
        document.getElementById("statusFilter");



    if (searchBox) {

        searchBox.addEventListener(
            "input",
            filterResults
        );

    }



    if (statusFilter) {

        statusFilter.addEventListener(
            "change",
            filterResults
        );

    }

}

function filterResults() {

    const searchBox =
        document.getElementById("search");


    const statusFilter =
        document.getElementById("statusFilter");


    const search =
        searchBox
            ? searchBox.value.toLowerCase()
            : "";


    const status =
        statusFilter
            ? statusFilter.value
            : "ALL";



    filteredResults =
        results.filter(item => {


            const searchable =
                Object.values(item)
                    .join(" ")
                    .toLowerCase();



            const matchesSearch =
                searchable.includes(search);



            const matchesStatus =
                status === "ALL" ||
                item.Status === status;



            return (
                matchesSearch &&
                matchesStatus
            );


        });



    currentPage = 1;


    renderPage();

}

/* ==========================================================
   DARK MODE
========================================================== */

function initializeTheme() {


    const button =
        document.getElementById("themeButton");


    if (!button) {

        return;

    }


    const savedTheme =
        localStorage.getItem("theme");


    if (savedTheme === "dark") {

        document.body.classList.add("dark");

        button.innerText =
            "☀️ Light Mode";

    }



    button.addEventListener(
        "click",
        () => {


            document.body.classList.toggle("dark");


            const darkMode =
                document.body.classList.contains("dark");


            localStorage.setItem(
                "theme",
                darkMode ? "dark" : "light"
            );


            button.innerText =
                darkMode
                    ? "☀️ Light Mode"
                    : "🌙 Dark Mode";


        }
    );

}