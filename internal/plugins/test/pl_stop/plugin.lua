ioutil.write_file(filepath.join(root, "pl_stop", "must_exist.txt"), "")
time.sleep(7)
ioutil.write_file(filepath.join(root, "pl_stop", "must_not_exist.txt"), "")