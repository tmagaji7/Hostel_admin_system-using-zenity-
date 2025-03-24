#!/bin/bash

HOSTEL_FILE="hostel_data.csv"

# Ensure the HOSTEL_FILE exists to avoid errors on initial run
if [ ! -f "$HOSTEL_FILE" ]; then
    touch "$HOSTEL_FILE"
fi

# Function to add a new resident
add_resident() {
    local name=$(zenity --entry --title="Add New Resident" --text="Enter Resident Name:")
    local room_number=$(zenity --entry --title="Add New Resident" --text="Enter Room Number:")
    local diet=$(zenity --list --title="Select Diet" --text="Select Diet:" --column="Option" "Vegetarian" "Non-Vegetarian")
    local warden_name=$(zenity --list --title="Select Warden" --text="Select Warden Name:" --column="Name" "Ramesh" "Ram" "Pawan" "Srikar")
    local gender=$(zenity --list --title="Select Gender" --text="Select Gender:" --column="Option" "Male" "Female")

    # Validate inputs
    if [ -z "$name" ] || [ -z "$room_number" ] || [ -z "$diet" ] || [ -z "$warden_name" ] || [ -z "$gender" ]; then
        zenity --error --text="Please provide name, room number, diet, warden, and select gender."
        return 1
    fi

    # Check if room number is already occupied and validate gender
    if grep -q ",$room_number," "$HOSTEL_FILE"; then
        local existing_genders=$(grep ",$room_number," "$HOSTEL_FILE" | cut -d ',' -f5)
        if echo "$existing_genders" | grep -qv "^$gender\$"; then
            zenity --error --text="Room $room_number is already occupied by a resident of different gender."
            return 1
        fi
    fi

    # Append resident details to hostel_data.csv
    echo "$name,$room_number,$diet,$warden_name,$gender" >> "$HOSTEL_FILE"
    zenity --info --text="Resident Added Successfully:\nName: $name\nRoom Number: $room_number\nDiet: $diet\nWarden: $warden_name\nGender: $gender"
}

# Function to view all residents
view_records() {
    if [ ! -s "$HOSTEL_FILE" ]; then
        zenity --info --text="No records found."
    else
        zenity --text-info --title="Hostel Records" --filename="$HOSTEL_FILE"
    fi
}

# Function to search for a resident
search_record() {
    local keyword=$(zenity --entry --title="Search Record" --text="Enter Name or Room Number:")

    # Search for resident by name or room number
    local result=$(grep -i "$keyword" "$HOSTEL_FILE")

    # Display search result
    if [ -n "$result" ]; then
        zenity --info --text="Record Details:\n$result"
    else
        zenity --info --text="Record not found"
    fi
}

# Function to display total number of residents by diet
total_by_diet() {
    local vegetarian_count=$(grep -ic ",Vegetarian$" "$HOSTEL_FILE")
    local non_vegetarian_count=$(grep -ic ",Non-Vegetarian$" "$HOSTEL_FILE")

    if [ "$vegetarian_count" -eq 0 ] && [ "$non_vegetarian_count" -eq 0 ]; then
        zenity --info --text="No residents found."
    else
        zenity --info --text="Total Residents:\nVegetarian: $vegetarian_count\nNon-Vegetarian: $non_vegetarian_count"
    fi
}

# Function to display students under each warden
students_under_warden() {
    local warden_report=""
    for warden in Ramesh Ram Pawan Srikar; do
        local count=$(grep -ic ",$warden," "$HOSTEL_FILE")
        warden_report+="$warden: $count\n"
    done
    zenity --info --text="Students Under Each Warden:\n$warden_report"
}

# Function to display statistics
display_statistics() {
    local total_count=$(wc -l < "$HOSTEL_FILE")
    local male_count=$(grep -c ",Male$" "$HOSTEL_FILE")
    local female_count=$(grep -c ",Female$" "$HOSTEL_FILE")

    zenity --info --text="Statistics:\nTotal Residents: $total_count\nMale Residents: $male_count\nFemale Residents: $female_count"
}

# Function to edit a resident record
edit_record() {
    local keyword=$(zenity --entry --title="Edit Record" --text="Enter Name or Room Number to Edit:")

    # Search for the record to edit
    local result=$(grep -i "$keyword" "$HOSTEL_FILE")

    # If record found, prompt for new details
    if [ -n "$result" ]; then
        local new_details=$(zenity --forms --title="Edit Resident Record" --text="Edit Resident Record" \
            --add-entry="Name" \
            --add-entry="Room Number" \
            --add-combo="Diet" --combo-values="Vegetarian|Non-Vegetarian" \
            --add-combo="Warden" --combo-values="Ramesh|Ram|Pawan|Srikar" \
            --add-combo="Gender" --combo-values="Male|Female")

        if [ -n "$new_details" ]; then
            # Replace old record with new details
            sed -i "/$keyword/c$new_details" "$HOSTEL_FILE"
            zenity --info --text="Record Updated Successfully:\nNew Details:\n$new_details"
        fi
    else
        zenity --info --text="Record not found"
    fi
}

# Function to delete a resident record
delete_record() {
    local keyword=$(zenity --entry --title="Delete Record" --text="Enter Name or Room Number to Delete:")

    # Search for the record to delete
    local result=$(grep -i "$keyword" "$HOSTEL_FILE")

    # If record found, delete it
    if [ -n "$result" ]; then
        sed -i "/$keyword/d" "$HOSTEL_FILE"
        zenity --info --text="Record Deleted Successfully:\nDeleted Record:\n$result"
    else
        zenity --info --text="Record not found"
    fi
}

# Loop for continuous menu display
while true; do
    # Display menu options
    choice=$(zenity --list --title="Hostel Management System" --text="Select an option:" --column="Option" \
        "Add Resident" "View Records" "Search Record" "Total by Diet" "Students Under Warden" "Statistics" "Edit Record" "Delete Record" "Exit")

    # Process user's choice
    case $choice in
        "Add Resident") add_resident ;;
        "View Records") view_records ;;
        "Search Record") search_record ;;
        "Total by Diet") total_by_diet ;;
        "Students Under Warden") students_under_warden ;;
        "Statistics") display_statistics ;;
        "Edit Record") edit_record ;;
        "Delete Record") delete_record ;;
        "Exit") echo "Exiting..."; exit 0 ;;
        *) echo "Invalid choice" ;;
    esac
done
