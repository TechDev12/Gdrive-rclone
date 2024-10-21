# Gdrive-rclone

Start by Cloning the repository

cd /home/backup
git clone https://github.com/TechDev12/Gdrive-rclone.git

if you already have rclone config or you wish to modify it you can configure rclone manually using "rclone config"

If rclone_config file exists you can append the configuration there to add your google drive configuration

Usage: ./backup_to_gd.sh [OPTIONS]

Options:
  --backup_path=PATH              Specify the directory to be backed up
                                   Example: --backup_path=/home/abjad/files
  --encryption_key=KEY            Specify the encryption key used
                                   Example: --encryption_key=HUHU@465123Maroun
  --remote_name=REMOTE            Specify the remote name configured with rclone if rclone_config file was added --remote_name must match the remote name in rclone_config
                                   Example: --remote_name=Google_Drive
  --service_account_file_path=PATH Specify the path to the service account JSON file
                                   Example: --service_account_file_path=/home/l0rd/service.json
  --help                          Show this help menu

Full Example Below

./backup_to_gd.sh --backup_path=/home/abjad/files --encryption_key=Your_enc_here --remote_name=Google_Drive --service_account_file_path=/home/l0rd/service.json

Script must be run as root thus will genereate a run.sh that you can add using a cronjob 

.Usage: ./run.sh <gdrive_folder_name>

