/*
 * Binoy Jayan [ binoyjayan@gmail.com ]
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>

#define PACKED __attribute__  ((packed))
#define LOGICAL_BLOCK_SIZE    512
#define ARRAY_SIZE(x)         (sizeof(x) / sizeof((x)[0]))

struct gpt_header {
	char signature[8];
	int revision;
	int header_size;
	uint32_t crc_header;
	int reserved;
	uint64_t lba_current;
	uint64_t lba_backup;
	uint64_t lba_first_usable;
	uint64_t lba_last_usable;
	uint8_t disk_guid[16];
	uint64_t lba_entry_start;
	int entry_count;
	int entry_size;
	uint32_t crc_entries;
	int reserved1[105];
} PACKED;

struct part_entry {
	uint8_t type_guid[16];
	uint8_t unique_guid[16];
	uint64_t lba_first;
	uint64_t lba_last;
	uint64_t attribute;
	uint16_t name[36];
} PACKED;

struct mbr_part_entry {
	uint8_t status;
	uint8_t start_head;
	uint16_t start_sector;
	uint8_t part_type;
	uint8_t end_head;
	uint16_t end_sector;
	uint32_t first_abs_sector;
	uint32_t sector_count;
} PACKED;

struct legacy_mbr {
	uint8_t boot_code[440];
	int unique_mbr_signature;
	short unknown;
	struct mbr_part_entry partition_record[4];
	uint16_t signature;
} PACKED;

struct options {
	int primary;
	int legacy;
	/* This option is for reading GPT data from a backup file where the
	 * GPT headers are saved by utilities like gdisk. This does not
	 */
	int saved;
	int guid;
	const char *filename;
};

// GUID partition type definition
struct part_type {
	const uint16_t mbr_type;
	const char *guid_type;
	const char *name;
};

// GUID partition types
static const struct part_type part_types[] = {
	0x0000, "00000000-0000-0000-0000-000000000000", "Unused entry",
	0x0100, "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7", "Microsoft basic data", // FAT-12
	0x0400, "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7", "Microsoft basic data", // FAT-16 < 32M
	0x0600, "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7", "Microsoft basic data", // FAT-16
	0x0700, "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7", "Microsoft basic data", // NTFS (or HPFS)
	0x0b00, "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7", "Microsoft basic data", // FAT-32
	0x0c00, "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7", "Microsoft basic data", // FAT-32 LBA
	0x0c01, "E3C9E316-0B5C-4DB8-817D-F92DF00215AE", "Microsoft reserved",
	0x0e00, "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7", "Microsoft basic data", // FAT-16 LBA
	0x1100, "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7", "Microsoft basic data", // Hidden FAT-12
	0x1400, "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7", "Microsoft basic data", // Hidden FAT-16 < 32M
	0x1600, "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7", "Microsoft basic data", // Hidden FAT-16
	0x1700, "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7", "Microsoft basic data", // Hidden NTFS (or HPFS)
	0x1b00, "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7", "Microsoft basic data", // Hidden FAT-32
	0x1c00, "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7", "Microsoft basic data", // Hidden FAT-32 LBA
	0x1e00, "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7", "Microsoft basic data", // Hidden FAT-16 LBA
	0x2700, "DE94BBA4-06D1-4D40-A16A-BFD50179D6AC", "Windows RE",
	0x3000, "7412F7D5-A156-4B13-81DC-867174929325", "ONIE boot",
	0x3001, "D4E6E2CD-4469-46F3-B5CB-1BFF57AFC149", "ONIE config",
	0x3900, "C91818F9-8025-47AF-89D2-F030D7000C2C", "Plan 9",
	0x4100, "9E1A2D38-C612-4316-AA26-8B49521E5A8B", "PowerPC PReP boot",
	0x4200, "AF9B60A0-1431-4F62-BC68-3311714A69AD", "Windows LDM data", // Logical disk manager
	0x4201, "5808C8AA-7E8F-42E0-85D2-E1E90434CFB3", "Windows LDM metadata", // Logical disk manager
	0x4202, "E75CAF8F-F680-4CEE-AFA3-B001E56EFC2D", "Windows Storage Spaces", // A newer LDM-type setup
	0x7501, "37AFFC90-EF7D-4E96-91C3-2D7AE055B174", "IBM GPFS", // General Parallel File System (GPFS)
	0x7f00, "FE3A2A5D-4F32-41A7-B725-ACCC3285A309", "ChromeOS kernel",
	0x7f01, "3CB8E202-3B7E-47DD-8A3C-7FF2A13CFCEC", "ChromeOS root",
	0x7f02, "2E0A753D-9E48-43B0-8337-B15192CB1B5E", "ChromeOS reserved",
	0x8200, "0657FD6D-A4AB-43C4-84E5-0933C84B4F4F", "Linux swap", // Linux swap (or Solaris on MBR)
	0x8300, "0FC63DAF-8483-4772-8E79-3D69D8477DE4", "Linux filesystem", // Linux native
	0x8301, "8DA63339-0007-60C0-C436-083AC8230908", "Linux reserved",
	0x8302, "933AC7E1-2EB4-4F13-B844-0E14E2AEF915", "Linux /home", // Linux /home (auto-mounted by systemd)
	0x8303, "44479540-F297-41B2-9AF7-D131D5F0458A", "Linux x86 root (/)", // Linux / on x86 (auto-mounted by systemd)
	0x8304, "4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709", "Linux x86-64 root (/)", // Linux / on x86-64 (auto-mounted by systemd)
	0x8305, "B921B045-1DF0-41C3-AF44-4C6F280D3FAE", "Linux ARM64 root (/)", // Linux / on 64-bit ARM (auto-mounted by systemd)
	0x8306, "3B8F8425-20E0-4F3B-907F-1A25A76F98E8", "Linux /srv", // Linux /srv (auto-mounted by systemd)
	0x8307, "69DAD710-2CE4-4E3C-B16C-21A1D49ABED3", "Linux ARM32 root (/)", // Linux / on 32-bit ARM (auto-mounted by systemd)
	0x8400, "D3BFE2DE-3DAF-11DF-BA40-E3A556D89593", "Intel Rapid Start",
	0x8e00, "E6D6D379-F507-44C2-A23C-238F2A3DF928", "Linux LVM",
	0xa000, "2568845D-2332-4675-BC39-8FA5A4748D15", "Android bootloader",
	0xa001, "114EAFFE-1552-4022-B26E-9B053604CF84", "Android bootloader 2",
	0xa002, "49A4D17F-93A3-45C1-A0DE-F50B2EBE2599", "Android boot",
	0xa003, "4177C722-9E92-4AAB-8644-43502BFD5506", "Android recovery",
	0xa004, "EF32A33B-A409-486C-9141-9FFB711F6266", "Android misc",
	0xa005, "20AC26BE-20B7-11E3-84C5-6CFDB94711E9", "Android metadata",
	0xa006, "38F428E6-D326-425D-9140-6E0EA133647C", "Android system",
	0xa007, "A893EF21-E428-470A-9E55-0668FD91A2D9", "Android cache",
	0xa008, "DC76DDA9-5AC1-491C-AF42-A82591580C0D", "Android data",
	0xa009, "EBC597D0-2053-4B15-8B64-E0AAC75F4DB1", "Android persistent",
	0xa00a, "8F68CC74-C5E5-48DA-BE91-A0C8C15E9C80", "Android factory",
	0xa00b, "767941D0-2085-11E3-AD3B-6CFDB94711E9", "Android fastboot/tertiary",
	0xa00c, "AC6D7924-EB71-4DF8-B48D-E267B27148FF", "Android OEM",
	0xa500, "516E7CB4-6ECF-11D6-8FF8-00022D09712B", "FreeBSD disklabel",
	0xa501, "83BD6B9D-7F41-11DC-BE0B-001560B84F0F", "FreeBSD boot",
	0xa502, "516E7CB5-6ECF-11D6-8FF8-00022D09712B", "FreeBSD swap",
	0xa503, "516E7CB6-6ECF-11D6-8FF8-00022D09712B", "FreeBSD UFS",
	0xa504, "516E7CBA-6ECF-11D6-8FF8-00022D09712B", "FreeBSD ZFS",
	0xa505, "516E7CB8-6ECF-11D6-8FF8-00022D09712B", "FreeBSD Vinum/RAID",
	0xa580, "85D5E45A-237C-11E1-B4B3-E89A8F7FC3A7", "Midnight BSD data",
	0xa581, "85D5E45E-237C-11E1-B4B3-E89A8F7FC3A7", "Midnight BSD boot",
	0xa582, "85D5E45B-237C-11E1-B4B3-E89A8F7FC3A7", "Midnight BSD swap",
	0xa583, "0394Ef8B-237E-11E1-B4B3-E89A8F7FC3A7", "Midnight BSD UFS",
	0xa584, "85D5E45D-237C-11E1-B4B3-E89A8F7FC3A7", "Midnight BSD ZFS",
	0xa585, "85D5E45C-237C-11E1-B4B3-E89A8F7FC3A7", "Midnight BSD Vinum",
	0xa600, "824CC7A0-36A8-11E3-890A-952519AD3F61", "OpenBSD disklabel",
	0xa800, "55465300-0000-11AA-AA11-00306543ECAC", "Apple UFS", // Mac OS X
	0xa900, "516E7CB4-6ECF-11D6-8FF8-00022D09712B", "FreeBSD disklabel", // NetBSD disklabel
	0xa901, "49F48D32-B10E-11DC-B99B-0019D1879648", "NetBSD swap",
	0xa902, "49F48D5A-B10E-11DC-B99B-0019D1879648", "NetBSD FFS",
	0xa903, "49F48D82-B10E-11DC-B99B-0019D1879648", "NetBSD LFS",
	0xa904, "2DB519C4-B10F-11DC-B99B-0019D1879648", "NetBSD concatenated",
	0xa905, "2DB519EC-B10F-11DC-B99B-0019D1879648", "NetBSD encrypted",
	0xa906, "49F48DAA-B10E-11DC-B99B-0019D1879648", "NetBSD RAID",
	0xab00, "426F6F74-0000-11AA-AA11-00306543ECAC", "Recovery HD",
	0xaf00, "48465300-0000-11AA-AA11-00306543ECAC", "Apple HFS/HFS+",
	0xaf01, "52414944-0000-11AA-AA11-00306543ECAC", "Apple RAID",
	0xaf02, "52414944-5F4F-11AA-AA11-00306543ECAC", "Apple RAID offline",
	0xaf03, "4C616265-6C00-11AA-AA11-00306543ECAC", "Apple label",
	0xaf04, "5265636F-7665-11AA-AA11-00306543ECAC", "AppleTV recovery",
	0xaf05, "53746F72-6167-11AA-AA11-00306543ECAC", "Apple Core Storage",
	0xaf06, "B6FA30DA-92D2-4A9A-96F1-871EC6486200", "Apple SoftRAID Status",
	0xaf07, "2E313465-19B9-463F-8126-8A7993773801", "Apple SoftRAID Scratch",
	0xaf08, "FA709C7E-65B1-4593-BFD5-E71D61DE9B02", "Apple SoftRAID Volume",
	0xaf09, "BBBA6DF5-F46F-4A89-8F59-8765B2727503", "Apple SoftRAID Cache",
	0xb300, "CEF5A9AD-73BC-4601-89F3-CDEEEEE321A1", "QNX6 Power-Safe",
	0xbc00, "0311FC50-01CA-4725-AD77-9ADBB20ACE98", "Acronis Secure Zone",
	0xbe00, "6A82CB45-1DD2-11B2-99A6-080020736631", "Solaris boot",
	0xbf00, "6A85CF4D-1DD2-11B2-99A6-080020736631", "Solaris root",
	0xbf01, "6A898CC3-1DD2-11B2-99A6-080020736631", "Solaris /usr & Mac ZFS", // Solaris/MacOS
	0xbf02, "6A87C46F-1DD2-11B2-99A6-080020736631", "Solaris swap",
	0xbf03, "6A8B642B-1DD2-11B2-99A6-080020736631", "Solaris backup",
	0xbf04, "6A8EF2E9-1DD2-11B2-99A6-080020736631", "Solaris /var",
	0xbf05, "6A90BA39-1DD2-11B2-99A6-080020736631", "Solaris /home",
	0xbf06, "6A9283A5-1DD2-11B2-99A6-080020736631", "Solaris alternate sector",
	0xbf07, "6A945A3B-1DD2-11B2-99A6-080020736631", "Solaris Reserved 1",
	0xbf08, "6A9630D1-1DD2-11B2-99A6-080020736631", "Solaris Reserved 2",
	0xbf09, "6A980767-1DD2-11B2-99A6-080020736631", "Solaris Reserved 3",
	0xbf0a, "6A96237F-1DD2-11B2-99A6-080020736631", "Solaris Reserved 4",
	0xbf0b, "6A8D2AC7-1DD2-11B2-99A6-080020736631", "Solaris Reserved 5",
	0xc001, "75894C1E-3AEB-11D3-B7C1-7B03A0000000", "HP-UX data",
	0xc002, "E2A1E728-32E3-11D6-A682-7B03A0000000", "HP-UX service",
	0xe100, "7412F7D5-A156-4B13-81DC-867174929325", "ONIE boot",
	0xe101, "D4E6E2CD-4469-46F3-B5CB-1BFF57AFC149", "ONIE config",
	0xea00, "BC13C2FF-59E6-4262-A352-B275FD6F7172", "Freedesktop $BOOT",
	0xeb00, "42465331-3BA3-10F1-802A-4861696B7521", "Haiku BFS",
	0xed00, "F4019732-066E-4E12-8273-346C5641494F", "Sony system partition",
	0xed01, "BFBFAFE7-A34F-448A-9A5B-6213EB736C22", "Lenovo system partition",
	0xef00, "C12A7328-F81F-11D2-BA4B-00A0C93EC93B", "EFI System", // Parted identifies these as having the "boot flag" set
	0xef01, "024DEE41-33E7-11D3-9D69-0008C781F39F", "MBR partition scheme", // Used to nest MBR in GPT
	0xef02, "21686148-6449-6E6F-744E-656564454649", "BIOS boot partition", // Used by GRUB
	0xf800, "4FBD7E29-9D25-41B8-AFD0-062C0CEFF05D", "Ceph OSD", // Ceph Object Storage Daemon
	0xf801, "4FBD7E29-9D25-41B8-AFD0-5EC00CEFF05D", "Ceph dm-crypt OSD", // Ceph Object Storage Daemon (encrypted)
	0xf802, "45B0969E-9B03-4F30-B4C6-B4B80CEFF106", "Ceph journal",
	0xf803, "45B0969E-9B03-4F30-B4C6-5EC00CEFF106", "Ceph dm-crypt journal",
	0xf804, "89C57F98-2FE5-4DC0-89C1-F3AD0CEFF2BE", "Ceph disk in creation",
	0xf805, "89C57F98-2FE5-4DC0-89C1-5EC00CEFF2BE", "Ceph dm-crypt disk in creation",
	0xfb00, "AA31E02A-400F-11DB-9590-000C2911D1B8", "VMWare VMFS",
	0xfb01, "9198EFFC-31C0-11DB-8F78-000C2911D1B8", "VMWare reserved",
	0xfc00, "9D275380-40AD-11DB-BF97-000C2911D1B8", "VMWare kcore crash protection",
	0xfd00, "A19D880F-05FC-4D3B-A006-743F0F84911E", "Linux RAID"
};

static const uint32_t crc32_tab[] = { 0x00000000L, 0x77073096L, 0xee0e612cL,
	0x990951baL, 0x076dc419L, 0x706af48fL, 0xe963a535L, 0x9e6495a3L,
	0x0edb8832L, 0x79dcb8a4L, 0xe0d5e91eL, 0x97d2d988L, 0x09b64c2bL,
	0x7eb17cbdL, 0xe7b82d07L, 0x90bf1d91L, 0x1db71064L, 0x6ab020f2L,
	0xf3b97148L, 0x84be41deL, 0x1adad47dL, 0x6ddde4ebL, 0xf4d4b551L,
	0x83d385c7L, 0x136c9856L, 0x646ba8c0L, 0xfd62f97aL, 0x8a65c9ecL,
	0x14015c4fL, 0x63066cd9L, 0xfa0f3d63L, 0x8d080df5L, 0x3b6e20c8L,
	0x4c69105eL, 0xd56041e4L, 0xa2677172L, 0x3c03e4d1L, 0x4b04d447L,
	0xd20d85fdL, 0xa50ab56bL, 0x35b5a8faL, 0x42b2986cL, 0xdbbbc9d6L,
	0xacbcf940L, 0x32d86ce3L, 0x45df5c75L, 0xdcd60dcfL, 0xabd13d59L,
	0x26d930acL, 0x51de003aL, 0xc8d75180L, 0xbfd06116L, 0x21b4f4b5L,
	0x56b3c423L, 0xcfba9599L, 0xb8bda50fL, 0x2802b89eL, 0x5f058808L,
	0xc60cd9b2L, 0xb10be924L, 0x2f6f7c87L, 0x58684c11L, 0xc1611dabL,
	0xb6662d3dL, 0x76dc4190L, 0x01db7106L, 0x98d220bcL, 0xefd5102aL,
	0x71b18589L, 0x06b6b51fL, 0x9fbfe4a5L, 0xe8b8d433L, 0x7807c9a2L,
	0x0f00f934L, 0x9609a88eL, 0xe10e9818L, 0x7f6a0dbbL, 0x086d3d2dL,
	0x91646c97L, 0xe6635c01L, 0x6b6b51f4L, 0x1c6c6162L, 0x856530d8L,
	0xf262004eL, 0x6c0695edL, 0x1b01a57bL, 0x8208f4c1L, 0xf50fc457L,
	0x65b0d9c6L, 0x12b7e950L, 0x8bbeb8eaL, 0xfcb9887cL, 0x62dd1ddfL,
	0x15da2d49L, 0x8cd37cf3L, 0xfbd44c65L, 0x4db26158L, 0x3ab551ceL,
	0xa3bc0074L, 0xd4bb30e2L, 0x4adfa541L, 0x3dd895d7L, 0xa4d1c46dL,
	0xd3d6f4fbL, 0x4369e96aL, 0x346ed9fcL, 0xad678846L, 0xda60b8d0L,
	0x44042d73L, 0x33031de5L, 0xaa0a4c5fL, 0xdd0d7cc9L, 0x5005713cL,
	0x270241aaL, 0xbe0b1010L, 0xc90c2086L, 0x5768b525L, 0x206f85b3L,
	0xb966d409L, 0xce61e49fL, 0x5edef90eL, 0x29d9c998L, 0xb0d09822L,
	0xc7d7a8b4L, 0x59b33d17L, 0x2eb40d81L, 0xb7bd5c3bL, 0xc0ba6cadL,
	0xedb88320L, 0x9abfb3b6L, 0x03b6e20cL, 0x74b1d29aL, 0xead54739L,
	0x9dd277afL, 0x04db2615L, 0x73dc1683L, 0xe3630b12L, 0x94643b84L,
	0x0d6d6a3eL, 0x7a6a5aa8L, 0xe40ecf0bL, 0x9309ff9dL, 0x0a00ae27L,
	0x7d079eb1L, 0xf00f9344L, 0x8708a3d2L, 0x1e01f268L, 0x6906c2feL,
	0xf762575dL, 0x806567cbL, 0x196c3671L, 0x6e6b06e7L, 0xfed41b76L,
	0x89d32be0L, 0x10da7a5aL, 0x67dd4accL, 0xf9b9df6fL, 0x8ebeeff9L,
	0x17b7be43L, 0x60b08ed5L, 0xd6d6a3e8L, 0xa1d1937eL, 0x38d8c2c4L,
	0x4fdff252L, 0xd1bb67f1L, 0xa6bc5767L, 0x3fb506ddL, 0x48b2364bL,
	0xd80d2bdaL, 0xaf0a1b4cL, 0x36034af6L, 0x41047a60L, 0xdf60efc3L,
	0xa867df55L, 0x316e8eefL, 0x4669be79L, 0xcb61b38cL, 0xbc66831aL,
	0x256fd2a0L, 0x5268e236L, 0xcc0c7795L, 0xbb0b4703L, 0x220216b9L,
	0x5505262fL, 0xc5ba3bbeL, 0xb2bd0b28L, 0x2bb45a92L, 0x5cb36a04L,
	0xc2d7ffa7L, 0xb5d0cf31L, 0x2cd99e8bL, 0x5bdeae1dL, 0x9b64c2b0L,
	0xec63f226L, 0x756aa39cL, 0x026d930aL, 0x9c0906a9L, 0xeb0e363fL,
	0x72076785L, 0x05005713L, 0x95bf4a82L, 0xe2b87a14L, 0x7bb12baeL,
	0x0cb61b38L, 0x92d28e9bL, 0xe5d5be0dL, 0x7cdcefb7L, 0x0bdbdf21L,
	0x86d3d2d4L, 0xf1d4e242L, 0x68ddb3f8L, 0x1fda836eL, 0x81be16cdL,
	0xf6b9265bL, 0x6fb077e1L, 0x18b74777L, 0x88085ae6L, 0xff0f6a70L,
	0x66063bcaL, 0x11010b5cL, 0x8f659effL, 0xf862ae69L, 0x616bffd3L,
	0x166ccf45L, 0xa00ae278L, 0xd70dd2eeL, 0x4e048354L, 0x3903b3c2L,
	0xa7672661L, 0xd06016f7L, 0x4969474dL, 0x3e6e77dbL, 0xaed16a4aL,
	0xd9d65adcL, 0x40df0b66L, 0x37d83bf0L, 0xa9bcae53L, 0xdebb9ec5L,
	0x47b2cf7fL, 0x30b5ffe9L, 0xbdbdf21cL, 0xcabac28aL, 0x53b39330L,
	0x24b4a3a6L, 0xbad03605L, 0xcdd70693L, 0x54de5729L, 0x23d967bfL,
	0xb3667a2eL, 0xc4614ab8L, 0x5d681b02L, 0x2a6f2b94L, 0xb40bbe37L,
	0xc30c8ea1L, 0x5a05df1bL, 0x2d02ef8dL
};

static uint32_t __efi_crc32(const void *buf, int len, uint32_t seed)
{
	int i;
	register uint32_t crc32val;
	const unsigned char *s = buf;
	crc32val = seed;
	for (i = 0; i < len; i++) {
		crc32val =
		    crc32_tab[(crc32val ^ s[i]) & 0xff] ^ (crc32val >> 8);
	}
	return crc32val;
}

uint32_t crc32(const void *buf, int len)
{
	return (__efi_crc32(buf, len, ~0L) ^ ~0L);
}

char * uuid_to_str(uint8_t * data)
{
	char * buf = (char *) malloc(37);
	const char * hex = "0123456789ABCDEF";

	char * p = buf;
	uint32_t num = *((uint32_t *) data);
	p += sprintf(p, "%08X-", num);
	data += 4;

	uint16_t num2 = *((uint16_t *) data);
	p += sprintf(p, "%04hX-", num2);
	data += 2;

	num2 = *((uint16_t *) data);
	p += sprintf(p, "%04hX-", num2);
	data += 2;

	int i;
	for (i = 0; i < 8; i++) {
		if (i == 2)
			*p++ = '-';
		*p++ = hex[data[i] >> 4];
		*p++ = hex[data[i] & 0xF];
	}

	buf[36] = '\0';
	return buf;
}

wchar_t *utf16_to_wchar(uint16_t * str, int len)
{
	int i = 0;
	wchar_t *buf = (wchar_t *) malloc((len + 1) * sizeof(wchar_t));
	for (; i < len; i++)
		buf[i] = (wchar_t) str[i];
	buf[len] = L'\0';
	return buf;
}

void print_legacy_mbr(int fd)
{
	int i;
	struct mbr_part_entry empty;
	struct legacy_mbr mbr;
	struct mbr_part_entry *p;

	memset(&empty, 0, sizeof(struct mbr_part_entry));
	memset(&mbr, 0, sizeof(struct legacy_mbr));
	read(fd, &mbr, sizeof(struct legacy_mbr));

	if (mbr.signature != 0xAA55) {
		puts("No Protective MBR Found!");
		return;
	}
	printf("---------------------------------------------------------------------------------------------------------\n");
	printf("Protective MBR [ signature : 0x%hX ]", mbr.signature);
	printf("\n---------------------------------------------------------------------------------------------------------\n");
        printf("%-9s %-12s %-12s %-13s", "Status", "Start head", "Start sect", "Part type");
        printf("%-9s %-12s %-16s %s", "End head", "End Sect", "First ABS sect", "Sect count");
	printf("\n---------------------------------------------------------------------------------------------------------\n");

	for (i = 0; i < 4; i++) {
		p = &mbr.partition_record[i];
		if (!memcmp(p, &empty, sizeof(struct mbr_part_entry)))
			continue;
		printf("%-9hhu %-12hhu %-12hu 0x%-11hhX", p->status, p->start_head, p->start_sector, p->part_type);
		printf("%-9hhu %-12hu %-16u %u\n", p->end_head, p->end_sector, p->first_abs_sector, p->sector_count);
	}
	puts("");
}

int disp_gpt_header(int fd, struct gpt_header * gpt, char *which)
{
	int n;
	char sz[9], *buf;
	memset(gpt, 0, sizeof(struct gpt_header));
	n = read(fd, gpt, sizeof(struct gpt_header));
	memcpy(sz, gpt->signature, 8);
	sz[8] = '\0';

	if (n < sizeof(struct gpt_header)) {
		printf("Got only %d bytes for the %s header!\n", n, which);
		return 1;
	}
	if (strcmp(sz, "EFI PART")) {
		printf("Invalid GPT %s header !\n", which);
		return 1;
	}

	printf("---------------------------------------------------------------------------------------------------------\n");
	printf("GPT Header [%s]\n", which);
	printf("---------------------------------------------------------------------------------------------------------\n");
	printf("Signature        : %s\n", sz);
	printf("Revision         : 0x%x\n", gpt->revision);
	printf("Header size      : %d\n", gpt->header_size);
	printf("Header CRC       : 0x%X\n", gpt->crc_header);
	printf("LBA Current      : %lu\n", gpt->lba_current);
	printf("LBA Alternate    : %lu\n", gpt->lba_backup);
	printf("LBA First usable : %lu\n", gpt->lba_first_usable);
	printf("LBA Last  usable : %lu\n", gpt->lba_last_usable);
	buf = uuid_to_str(gpt->disk_guid);
	printf("Disk GUID        : %s\n", buf);
	free(buf);
	printf("LBA Entry start  : %lu\n", gpt->lba_entry_start);
	printf("Entry count      : %d\n", gpt->entry_count);
	printf("Entry size       : %d\n", gpt->entry_size);
	printf("Entries CRC      : 0x%X\n", gpt->crc_entries);
	printf("---------------------------------------------------------------------------------------------------------\n");

	uint32_t oldcrc = gpt->crc_header;
	gpt->crc_header = 0;
	if (crc32(gpt, gpt->header_size) != oldcrc)
		fputs("Bad header CRC !\n", stderr);
	gpt->crc_header = oldcrc;

	return 0;
}

const struct part_type* guid_lookup(char *g)
{
	int i;

	for (i = 0; i < ARRAY_SIZE(part_types); i++) {
		if (!strcmp(part_types[i].guid_type, g))
			return &part_types[i];
	}
	return NULL;
}

void print_gpt_partitions(int fd, const struct gpt_header * gpt, char *which, int guid)
{
	char *tmp;
	const char *gstr;
	const struct part_type* ptype;
	int i = 0;
	int entries_size = gpt->entry_count * gpt->entry_size;
	char *buf = (char *) malloc(entries_size);

	read(fd, buf, entries_size);
	wchar_t *gpt_entry_name;
	struct part_entry *gentry = (struct part_entry *) buf;
	struct part_entry gentry_empty;
	memset(&gentry_empty, 0, sizeof(struct part_entry));

	printf("Parition entries [%s]\n", which);
	printf("-----------------------------------------------------------------------------------------------------------------------------\n");

	printf("%-37s %-37s %-10s %-10s %-6s %s", "Type GUID", "Unique GUID", "LBA First", "LBA Last", "Attr", "Name\n");
	printf("-----------------------------------------------------------------------------------------------------------------------------\n");
	for (; i < gpt->entry_count; i++) {
		if (!memcmp(gentry, &gentry_empty, sizeof(struct part_entry)))
			continue;
		gpt_entry_name = utf16_to_wchar(gentry->name, 36);
		tmp = uuid_to_str(gentry->type_guid);
		if (guid) {
			printf("%-37s ", tmp);
		} else {
			ptype = guid_lookup(tmp);
			if (ptype)
				printf("0x%04hx %-30s ", ptype->mbr_type, ptype->name);
			else
				printf("%-37s ", tmp);
		}
		free(tmp);
		tmp = uuid_to_str(gentry->unique_guid);
		printf("%-37s ", tmp);
		free(tmp);
		printf("%-10lu %-10lu 0x%-4lu %ls\n",
			gentry->lba_first, gentry->lba_last,
			gentry->attribute, gpt_entry_name);

		free(gpt_entry_name);
		gentry++;
	}

	printf("-----------------------------------------------------------------------------------------------------------------------------\n");
	if (crc32(buf, entries_size) != gpt->crc_entries)
		fputs("Bad crc_entries.\n", stderr);

	free(buf);
}

const char *usage_str = "\n" \
	"Usage: gread [-h|--help] [-b|--backup] [-m|--mbr] [-s|--saved] [-g|--guid] <device file>\n\n" \
	"--mbr     : Displays legacy-mbr headers\n"\
	"--backup  : Displays backup headers and partition table instead of primary\n"\
	"--guid    : Display the GUID type values instead of names\n"\
	"--saved   : Display the GPT data saved in a file\n"\
	"\nExamples:\n\n"\
	"  gread -m /dev/sda\n" \
	"  gread -b /dev/sda\n" \
	"  gread -g /dev/sda\n" \
	"  gread -s gpt_data.bin\n";

static int is_arg(const char *arg, const char *ch1, const char *ch2)
{
	if (strcmp(arg, ch1) && strcmp(arg, ch2))
		return 0;
	return 1;
}

int get_options(int argc, const char * argv[], struct options *o)
{
	int i, found = 0;

	o->primary = 1;
	o->saved = 0;
	o->legacy = 0;
	o->guid = 0;
	o->filename = NULL;

	if (argc < 2) {
		fputs("Missing argument !\n", stderr);
		puts(usage_str);
		return 1;
	}

	for(i = 1; i < argc; i++) {
		if (argv[i][0] == '-') {
			if (is_arg(argv[i], "-h", "--help")) {
				puts(usage_str);
				return 1;
			}
			else if (is_arg(argv[i], "-b", "--backup"))
				o->primary = 0;
			else if (is_arg(argv[i], "-m", "--mbr"))
				o->legacy = 1;
			else if (is_arg(argv[i], "-g", "--guid"))
				o->guid = 1;
			else if (is_arg(argv[i], "-s", "--saved"))
				o->saved = 1;
			else {
				fprintf(stderr, "Invalid argument %s!\n", argv[i]);
				puts(usage_str);
				return 1;
			}
		} else {
			if (o->filename) {
				fputs("Specify only one device !\n", stderr);
				return 1;
			}
			o->filename = argv[i];
		}
	}

	if (!o->filename) {
		fputs("Missing device file as argument !\n", stderr);
		return 1;
	}

	return 0;
}

static void lba_align(const char *s, int fd, long pos, int align)
{
	if (pos % LOGICAL_BLOCK_SIZE) {
		printf("\nThe device does not end in a valid LBA boundary\n");
		pos = (pos / align) * align;
		printf("Aligning the %s to %ld [LBA %ld]\n\n", s, pos, pos/align);
		lseek(fd, pos, SEEK_SET);
	}
}

int main(int argc, const char * argv[])
{
	int exitCode = EXIT_SUCCESS;
	long n;
	struct gpt_header header;
	struct options o;

	if (get_options(argc, argv, &o))
		return 0;

	int fd = open(o.filename, O_RDONLY);
	if (fd == -1) {
		perror("Can't open device");
		return EXIT_FAILURE;
	}

	if (o.legacy)
		print_legacy_mbr(fd);
	else
		lseek(fd, LOGICAL_BLOCK_SIZE, SEEK_SET);

	// If reading GPT data from a saved file
	if (o.saved) {
		if (disp_gpt_header(fd, &header, "Primary"))
			goto end;
		if (disp_gpt_header(fd, &header, "Backup"))
			goto end;
		print_gpt_partitions(fd, &header, "common", o.guid);
		goto end;
	}

	// Display primary header and partition entries
	if (o.primary) {
		if (disp_gpt_header(fd, &header, "Primary"))
			goto end;
		print_gpt_partitions(fd, &header, "Primary", o.guid);
		goto end;
	}

	// Seek to the backup header location at the last LBA
	if ((n = lseek(fd, -LOGICAL_BLOCK_SIZE, SEEK_END)) == -1) {
		perror("Can't read backup header");
		exitCode = EXIT_FAILURE;
		goto end;
	}

	lba_align("header", fd, n, LOGICAL_BLOCK_SIZE);
	disp_gpt_header(fd, &header, "Backup");

	// Seek to the backup partition entries
	if ((n = lseek(fd, -1 * (header.entry_count * header.entry_size +
		   LOGICAL_BLOCK_SIZE), SEEK_END)) == -1) {
		perror("Can't read backup entries");
		exitCode = EXIT_FAILURE;
		goto end;
	}
	lba_align("partition table", fd, n, LOGICAL_BLOCK_SIZE);
	print_gpt_partitions(fd, &header, "Backup", o.guid);

end:
	close(fd);
	return exitCode;
}

