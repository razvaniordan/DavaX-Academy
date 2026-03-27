# PL/SQL Debugging Framework and Salary Adjustment Procedure

### Purpose

First, it creates a small debugging framework that can record what happens while a PL/SQL procedure is running.  
Second, it uses that framework in a procedure that updates employee salaries.

The goal is to make the execution of the procedure easier to follow, understand and debug.

When a PL/SQL procedure runs, it can be hard to see:
- which step it reached
- what values it was working with
- where an error happened

This task stores debug information in a log table.

At the same time, it applies a business rule to employee salaries:
- if an employee has a commission percentage, the salary is increased by that percentage
- if the commission percentage is null, the salary is increased by 2%

### Debug log table
This table stores log records generated during execution.

Each log contains information such as:
- the module or procedure name
- the logical line/checkpoint in the procedure
- the message describing what happened
- the time of the log
- the session that generated it

### Debug package
The debug package provides reusable utilities for logging.

It is responsible for:
- enabling debug mode
- disabling debug mode
- writing log entries
- formatting general messages
- formatting variable values
- formatting error messages

### Employees table
This table contains employee data used for testing the procedure, including salary and commission percentage.

### Salary adjustment procedure
This procedure processes employees one by one, calculates the new salary based on the commission rule, updates the employee record and writes debug information during execution.

## Flow of the solution

The overall flow is:

1. Debug mode is enabled.
2. The salary adjustment procedure starts.
3. The procedure reads each employee.
4. It logs useful information such as employee id, salary, commission percentage and calculated new salary.
5. It updates the salary based on the required business rule.
6. It continues until all employees are processed.
7. It logs that the procedure completed successfully.
8. If an error occurs, it logs the error message.
9. Debug mode can then be disabled.
