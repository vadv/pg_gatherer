package secrets

import (
	"io/ioutil"
	"log"
	"sync"

	"gopkg.in/yaml.v2"
)

// Storage for secrets
type Storage struct {
	mutex    sync.Mutex
	filename string
	data     map[string]string
}

// New return new Secret
func New(filename string) *Storage {
	result := &Storage{
		mutex:    sync.Mutex{},
		filename: filename,
		data:     make(map[string]string),
	}
	result.Read()
	return result
}

// Read secrets from file
func (s *Storage) Read() {
	if s.filename != `` {
		log.Printf("[INFO] reading secret file: %s\n", s.filename)
	} else {
		log.Printf("[INFO] skip read secret file: not specified\n")
	}
	s.mutex.Lock()
	defer s.mutex.Unlock()
	result := make(map[string]string)
	data, err := ioutil.ReadFile(s.filename)
	if err != nil {
		log.Printf("[ERROR] read secret file: %s\n", err.Error())
		return
	}
	if errYaml := yaml.Unmarshal(data, &result); errYaml != nil {
		log.Printf("[ERROR] parse secret file: %s\n", errYaml.Error())
	} else {
		log.Printf("[INFO] secret file %s readed\n", s.filename)
	}
	s.data = result
}

// get value
func (s *Storage) get(key string) *string {
	s.mutex.Lock()
	defer s.mutex.Unlock()
	result, ok := s.data[key]
	if !ok {
		return nil
	}
	return &result
}
