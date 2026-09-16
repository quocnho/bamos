package embedding

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

type openAIEmbeddingReq struct {
	Input string `json:"input"`
}

type openAIEmbeddingResp struct {
	Data []struct {
		Embedding []float32 `json:"embedding"`
	} `json:"data"`
}

type VectorClient struct {
	llamaHost string
	client    *http.Client
}

func NewVectorClient(llamaHost string) *VectorClient {
	return &VectorClient{
		llamaHost: llamaHost,
		client:    &http.Client{Timeout: 1200 * time.Millisecond},
	}
}

func (vc *VectorClient) SetHost(host string) {
	vc.llamaHost = host
}

func (vc *VectorClient) GetEmbedding(ctx context.Context, text string) ([]float32, error) {
	reqBody, _ := json.Marshal(openAIEmbeddingReq{Input: text})
	url := fmt.Sprintf("%s/v1/embeddings", vc.llamaHost)

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewBuffer(reqBody))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := vc.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("embedding status: %d", resp.StatusCode)
	}

	var res openAIEmbeddingResp
	if err := json.NewDecoder(resp.Body).Decode(&res); err != nil {
		return nil, err
	}

	if len(res.Data) == 0 || len(res.Data[0].Embedding) == 0 {
		return nil, fmt.Errorf("no embedding returned")
	}

	return res.Data[0].Embedding, nil
}
