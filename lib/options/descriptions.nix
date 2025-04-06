{ ... }:

{
    exports = _: {};

    topLevel = ''
        **intransient**
        : _(adjective)_ Not transient; not passing away; permanent. ([Wiktionary])

        In the context of this module, "intransient" refers to persistent data, as
        contrasted with temporary, ephemeral data.

        [Wiktionary]: <https://en.wiktionary.org/wiki/intransient>
    '';

    datastores = ''
        Locations in which intransient data will be stored.
        
        Each datastore defines a set of files and directories which are stored at
        the datastore's root path, and, on boot, linked or bind-mounted into the
        filesystem. This means you can define entries for the locations you want to
        keep, and use a tmpfs or other volatile storage for your root filesystem,
        so that only the files you designate will remain after a reboot.

        You can use multiple datastores to designate different roles for files, or
        to store them in different locations. For example, you can have a "safe"
        datastore, whose root path gets backed up, and use it for the files you care
        about keeping, like documents and photos. Then, you can have a "volatile"
        datastore, which gets excluded from backups, where you store temporary or
        easily replaced files, like caches, downloaded games or media, etc. Some other
        examples: SSD vs. HDD storage; RAID vs. non-RAID; encrypted vs. cleartext.
        And since all the entries are linked into the tree, you never need to sort
        files into individual mount points, and you can reuse the same configuration
        across machines that have different storage systems by overriding the
        datastore root paths.
    '';

    perms = {
        user = ''
            The user that will own this entry in the datastore and filesystem.
        '';

        group = ''
            The group that will own this entry in the datastore and filesystem.
        '';

        mode = ''
            The default mode that this entry should have in the datastore, if it
            doesn't already exist there.
        '';
    };

    entry = {
        path = ''
            The entry's location, relative to the datastore's base path.
        '';

        method = ''
            The method by which this entry should be interpolated into the filesystem.
        '';

        basePath = ''
            The base path under which this entry is found.
        '';

        kind = ''
            Whether the entry is a file or directory.
        '';

        hideMount = ''
            Whether to hide the mount from being shown in lists of mounted drives.
        '';
    };

    ds = {
        path = ''
            The root path of this datastore, where intransient files are placed.
        '';

        hideBindMounts = ''
            Whether to prevent bind-mounts for this datastore from showing up
            in lists of mounted drives.
        '';

        entryList = ''
            Entries to include in the datastore.
        '';

        byPath = ''
            An attrset where the keys are paths and the values are entries relative
            to those paths. This lets you define multiple entries under the same path
            without repeating the base path each time.
        '';

        etc = ''
            Entries to link into the /etc directory. Uses a different method that is
            compatible with NixOS's `system.etc.overlay`, so it only allows a subset
            of the options available for normal entries.
        '';
    };

    users = let
        circular = ''
            This cannot be retrieved automatically due to a circular dependency between
            `fileSystems` and `users` in NixOS.
        '';
    in {
        topLevel = ''
            These entries are relative to the user's home directory. Their default
            permissions are set to the user's UID and GID. This acts as a convenient
            way to define persistent files for your home directory without needing to
            set the permissions manually for each entry.
        '';

        homePath = ''
            Path of the user's home directory.

            ${circular}
        '';

        defaultUser = ''
            The username of the owner that these entries will have by default.

            ${circular}
        '';

        defaultGroup = ''
            The name of the group that these entries will have by default.

            ${circular}
        '';
    };
}

# vim: set et sw=4 ts=4:
