#include <iostream>
#include <fstream>
#include <string>

int main()
{
    const int numFiles = 8;
    std::string filePaths[numFiles] = {"Bill/bill_funtion.sql", "Customer/customer_function.sql", "Employee/employee_function.sql",
                                       "Location/location_function.sql", "Operation/operation.sql", "Product/product_function.sql", "Report/report.sql",
                                       "Reservation/reservation.sql"};
    std::string outputFilePath = "output.sql";
    std::ofstream outputFile(outputFilePath);

    for (int i = 0; i < numFiles; ++i)
    {
        std::ifstream inputFile(filePaths[i]);
        if (inputFile.is_open())
        {
            outputFile << inputFile.rdbuf();
            inputFile.close();
        }
        else
        {
            std::cerr << "Error opening file " << filePaths[i] << std::endl;
            return 1;
        }
    }

    outputFile.close();
    std::cout << "Concatenation successful!" << std::endl;

    return 0;
}
