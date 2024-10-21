#!/bin/bash

# Function to display the help menu
show_help() {
    echo "Usage: ./backup_to_gd.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --backup_path=PATH              Specify the directory to be backed up"
    echo "                                   Example: --backup_path=/home/abjad/files"
    echo "  --encryption_key=KEY            Specify the encryption key used"
    echo "                                   Example: --encryption_key=HUHU@465123Maroun"
    echo "  --remote_name=REMOTE            Specify the remote name configured with rclone if rclone_config file was added --remote_name must match the remote name in rclone_config"
    echo "                                   Example: --remote_name=Google_Drive"
    echo "  --service_account_file_path=PATH Specify the path to the service account JSON file"
    echo "                                   Example: --service_account_file_path=/home/l0rd/service.json"
    echo "  --help                          Show this help menu"
    echo ""
    echo "Full Example Below"    
    echo ""
    echo "./backup_to_gd.sh --backup_path=/home/backup/tmp --encryption_key=465123Maroun --remote_name=Google_Drive --service_account_file_path=/home/backup/service.json"
    echo ""
    echo ""
    echo ""    
    echo ""
    echo ""
}

# Default values
backup_path=""
encryption_key=""
remote_name=""
service_account_file_path=""

# Parse the command-line arguments
for arg in "$@"
do
    case $arg in
        --backup_path=*) 
            backup_path="${arg#*=}"
            ;;
        --encryption_key=*) 
            encryption_key="${arg#*=}"
            ;;
        --remote_name=*) 
            remote_name="${arg#*=}"
            ;;
        --service_account_file_path=*) 
            service_account_file_path="${arg#*=}"
            ;;
        --help) 
            show_help
            exit 0
            ;;
        *) 
            echo "Unknown option: $arg"
            show_help
            exit 1
            ;;
    esac
done

# Check if required arguments are provided
if [[ -z "$backup_path" || -z "$encryption_key" || -z "$remote_name" || -z "$service_account_file_path" ]]; then
    echo "Error: Missing required arguments."
    show_help
    exit 1
fi

# Display parsed values (or proceed with your script logic)
echo "Backup Path: $backup_path"
echo "Encryption Key: $encryption_key"
echo "Remote Name: $remote_name"
echo "Service Account File Path: $service_account_file_path"

# Here you can add the logic to perform the backup using rclone and encryption, like:
# rclone copy $backup_path $remote_name:backup --drive-service-account-file $service_account_file_path --crypt-password $encryption_key


# Check if the script is run as root (UID 0 means root)
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Please run as root."
   exit 1
fi

# Check if rclone is installed
if ! command -v rclone &> /dev/null
then
    echo "rclone is not installed. Installing now..."
    
    # Check if the user has sudo privileges (prompt for password if necessary)
    if true; then
        # Install rclone using curl
        curl https://rclone.org/install.sh | bash

        # Verify the installation
        if command -v rclone &> /dev/null; then
            echo "rclone installed successfully."
        else
            echo "Failed to install rclone."
            exit 1
        fi
    else
        echo "Error: You do not have sudo privileges."
        exit 1
    fi
else
    echo "rclone is already installed."
fi

# Check if the rclone_config file exists in the current directory
if [[ -f "rclone_config" ]]; then
    echo "Appending contents of rclone_config to /root/.config/rclone/rclone.conf..."

    # Create the directory if it doesn't exist
    mkdir -p /root/.config/rclone

    # Append the contents of rclone_config to rclone.conf
    cat rclone_config >> /root/.config/rclone/rclone.conf

    echo "Contents appended successfully."
else
    echo "Error: rclone_config file does not exist in the current directory."
    exit 1
fi


# Create run file for the backup 
echo "#!/bin/bash" > run.sh

echo "########################" >> run.sh
echo "#Your Backup script to directory goes here" >> run.sh
echo "" >> run.sh
echo "" >> run.sh
echo "" >> run.sh
echo "########################" >> run.sh



echo "# Check if an argument was provided" >> run.sh
echo 'if [ "$#" -ne 1 ]; then' >> run.sh
echo '    echo "Usage: $0 <gdrive_folder_name>"' >> run.sh
echo '    exit 1' >> run.sh
echo 'fi' >> run.sh

echo "# Assign the argument to a variable" >> run.sh
echo 'gdrive_folder_name="$1"' >> run.sh



echo "#Copy Local directory to Google Drive Team remote." >> run.sh
echo "# Encrypt each file in the directory and replace the original with the encrypted version" >> run.sh
echo "echo \"Encrypting all files in $backup_path...\"" >> run.sh
echo "for file in \"$backup_path\"/*; do" >> run.sh
echo "  if [[ -f \$file ]]; then" >> run.sh
echo "    echo Encrypting file: \$file" >> run.sh
echo "    openssl enc -aes-256-cbc -salt -in "\$file" -out "\$file.enc" -k '$encryption_key' -pbkdf2" >> run.sh   
echo "    # Replace the original file with the encrypted version" >> run.sh
echo "    rm "\$file"" >> run.sh
echo "  fi" >> run.sh
echo "done" >> run.sh
echo "echo \"All files encrypted: Success\"" >> run.sh


echo "current_date=\$(date +"%Y-%m-%d")" >> run.sh
echo "#Rotate Log every 14 days:" >> run.sh
echo "find . -name 'log_*' -type f -mtime +14 -exec rm {} \;" >> run.sh
echo "rclone copy $backup_path $remote_name:/\$gdrive_folder_name --progress -vv > log_\$current_date.log" >> run.sh
echo "echo \"All files uploaded: Success\"" >> run.sh
echo "rclone check $backup_path $remote_name:/\$gdrive_folder_name >> log_\$current_date.log"  >> run.sh
echo "#Uploading raw logs" >> run.sh
echo "rclone copy log_\$current_date $remote_name:/\$gdrive_folder_name --progress -vv" >> run.sh
echo "rm $backup_path/*.enc" >> run.sh
chmod +x run.sh
