package installation

import (
	"github.com/gruntwork-io/terratest/modules/k8s"
)

func (s *configurationTest) TearDownTest() {
	if !s.T().Failed() {
		k8s.DeleteNamespace(s.T(), s.options.KubectlOptions, s.namespace)
	} else {
		s.log.Logf(s.T(), "Test failed on namespace %s. Omitting cleanup.", s.namespace)
	}
}
