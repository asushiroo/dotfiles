# Comprehensive Composed Image Retrieval (CIR) Baseline Papers

本文档汇总了 `paper-meta` 中最近两年的定会且**已开源**论文的**详细多指标 Baseline 数据**。包含 CIRR, FashionIQ 的全维度测试结果以及部分论文在 Shoes, Fashion200k, CIRCO 和 Fine-Grained 数据集上的表现。

## 1. CIRR Dataset Benchmark

| Rank (R@1) | Category   | Paper Title                                                                                      | R@1   | R@5   | R@10  | R@50  | R_sub@1 | R_sub@2 | R_sub@3 | Avg Metric | Open Source                                             | Meta Index                                                                                                                                 |
| :--------- | :--------- | :----------------------------------------------------------------------------------------------- | :---- | :---- | :---- | :---- | :------ | :------ | :------ | :--------- | :------------------------------------------------------ | :----------------------------------------------------------------------------------------------------------------------------------------- |
| 1          | Supervised | **DetailFusion: A Dual-branch Framework with Detail Enhancement for Composed Image Retrieval**   | 55.76 | 84.77 | 91.66 | 98.58 | 82.22   | 93.66   | 97.5    | 83.5       | [Github](https://github.com/HaHaJun1101/DetailFusion)   | [Meta](./paper-meta/Supervised_CIR/aft2024/DetailFusion:_A_Dual-branch_Framework_with_Detail_Enhancement_for_Composed_Image_Retrieval.md)  |
| 2          | Supervised | **ConText-CIR: Learning from Concepts in Text for Composed Image Retrieval**                     | 55.24 | 84.85 | 90.75 | 98.82 | 82.96   | 93.12   | 97.04   | -          | [Github](https://github.com/mvrl/ConText-CIR)           | [Meta](./paper-meta/Supervised_CIR/aft2024/ConText-CIR:_Learning_from_Concepts_in_Text_for_Composed_Image_Retrieval.md)                    |
| 3          | Supervised | **CaLa: Complementary Association Learning for Augmenting Composed Image Retrieval**             | 49.11 | 81.21 | 89.59 | 98.0  | 76.27   | 91.04   | 96.46   | 78.74      | [Github](https://github.com/Chiangsonw/CaLa)            | [Meta](./paper-meta/Supervised_CIR/aft2024/CaLa:_Complementary_Association_Learning_for_Augmenting_Composed_Image_Retrieval.md)            |
| 4          | Supervised | **CoLLM: A Large Language Model for Composed Image Retrieval**                                   | 45.8  | -     | 84.7  | 95.8  | -       | -       | -       | -          | [Github](https://github.com/hmchuong/CoLLM)             | [Meta](./paper-meta/Supervised_CIR/aft2024/CoLLM:_A_Large_Language_Model_for_Composed_Image_Retrieval.md)                                  |
| 5          | Supervised | **Bi-directional Training for Composed Image Retrieval via Text Prompt Learning**                | 42.36 | 75.46 | 83.88 | 96.27 | 72.9    | 88.27   | 95.93   | 74.18      | [Github](https://github.com/Cuberick-Orion/Bi-Blip4CIR) | [Meta](./paper-meta/Supervised_CIR/aft2024/Bi-directional_Training_for_Composed_Image_Retrieval_via_Text_Prompt_Learning.md)               |
| 6          | Zero-Shot  | **Semantic Editing Increment Benefits Zero-Shot Composed Image Retrieval**                       | 38.87 | 69.42 | 79.42 | -     | 74.15   | 89.23   | 95.71   | -          | [Github](https://github.com/yzy-bupt/SEIZE)             | [Meta](./paper-meta/Zero-Shot_CIR/aft2024/Semantic_Editing_Increment_Benefits_Zero-Shot_Composed_Image_Retrieval.md)                       |
| 7          | Zero-Shot  | **Zero-shot Composed Text-Image Retrieval**                                                      | 37.87 | 68.88 | -     | 93.86 | 69.79   | -       | -       | -          | [Github](https://github.com/Code-kunkun/ZS-CIR)         | [Meta](./paper-meta/Zero-Shot_CIR/aft2024/Zero-shot_Composed_Text-Image_Retrieval.md)                                                      |
| 8          | Zero-Shot  | **Training-free Zero-shot Composed Image Retrieval via Weighted Modality Fusion and Similarity** | 31.04 | 60.41 | 72.27 | 90.89 | 58.84   | 78.92   | 89.64   | -          | [Github](https://github.com/whats2000/WeiMoCIR)         | [Meta](./paper-meta/Zero-Shot_CIR/aft2024/Training-free_Zero-shot_Composed_Image_Retrieval_via_Weighted_Modality_Fusion_and_Similarity.md) |

## 2. FashionIQ Dataset Benchmark

| Category   | Paper Title                                                                                                    | Dress R@10 | Dress R@50 | Shirt R@10 | Shirt R@50 | Toptee R@10 | Toptee R@50 | Avg R@10 | Avg R@50 | Overall Avg | Open Source                                                      |
| :--------- | :------------------------------------------------------------------------------------------------------------- | :--------- | :--------- | :--------- | :--------- | :---------- | :---------- | :------- | :------- | :---------- | :--------------------------------------------------------------- |
| Supervised | **DetailFusion: A Dual-branch Framework with Detail Enhancement for Composed Image Retrieval**                 | 51.34      | 74.05      | 58.12      | 75.95      | 61.22       | 80.09       | -        | -        | 66.79       | [Github](https://github.com/HaHaJun1101/DetailFusion)            |
| Supervised | **CaLa: Complementary Association Learning for Augmenting Composed Image Retrieval**                           | 42.38      | 66.08      | 46.76      | 68.16      | 50.93       | 73.42       | -        | -        | 57.96       | [Github](https://github.com/Chiangsonw/CaLa)                     |
| Supervised | **Bi-directional Training for Composed Image Retrieval via Text Prompt Learning**                              | 42.09      | 67.33      | 41.76      | 64.28      | 46.61       | 70.32       | -        | -        | 55.4        | [Github](https://github.com/Cuberick-Orion/Bi-Blip4CIR)          |
| Supervised | **Cross-Modal Attention Preservation with Self-Contrastive Learning for Composed Query-Based Image Retrieval** | 36.44      | 64.25      | 34.83      | 60.06      | 41.79       | 69.12       | -        | -        | 51.08       | [Github](https://github.com/CFM-MSG/Code_CMAP)                   |
| Zero-Shot  | **Zero-shot Composed Text-Image Retrieval**                                                                    | -          | -          | -          | -          | -           | -           | 34.36    | 55.13    | 44.75       | [Github](https://github.com/Code-kunkun/ZS-CIR)                  |
| Zero-Shot  | **Semantic Editing Increment Benefits Zero-Shot Composed Image Retrieval**                                     | 39.61      | 61.02      | 43.6       | 65.42      | 45.94       | 71.12       | 43.05    | 65.85    | -           | [Github](https://github.com/yzy-bupt/SEIZE)                      |
| Supervised | **CoLLM: A Large Language Model for Composed Image Retrieval**                                                 | -          | -          | -          | -          | -           | -           | 39.1     | 60.7     | -           | [Github](https://github.com/hmchuong/CoLLM)                      |
| Zero-Shot  | **Training-free Zero-shot Composed Image Retrieval via Weighted Modality Fusion and Similarity**               | 30.99      | 52.45      | 37.73      | 56.18      | 42.38       | 63.23       | 37.03    | 57.29    | -           | [Github](https://github.com/whats2000/WeiMoCIR)                  |
| Supervised | **Composed Image Retrieval with Text Feedback via Multi-Grained Uncertainty Regularization**                   | 32.61      | 61.34      | 33.23      | 62.55      | 41.4        | 72.51       | 35.75    | 65.47    | -           | [Github](https://github.com/Monoxide-Chen/uncertainty_retrieval) |

## 3. Other Datasets (Shoes, Fashion200k, CIRCO, Fine-Grained)

| Category   | Paper Title                                                                                                    | Other Datasets Metrics                                               | Open Source                                                      | Meta Index                                                                                                                                                |
| :--------- | :------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------- | :--------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Supervised | **CoLLM: A Large Language Model for Composed Image Retrieval**                                                 | CIRCO (mAP@5: 19.7, mAP@10: 20.4)                                    | [Github](https://github.com/hmchuong/CoLLM)                      | [Meta](./paper-meta/Supervised_CIR/aft2024/CoLLM:_A_Large_Language_Model_for_Composed_Image_Retrieval.md)                                                 |
| Supervised | **Cross-Modal Attention Preservation with Self-Contrastive Learning for Composed Query-Based Image Retrieval** | Shoes (R@1: 20.73, R@10: 55.96, R@50: 80.98)                         | [Github](https://github.com/CFM-MSG/Code_CMAP)                   | [Meta](./paper-meta/Supervised_CIR/aft2024/Cross-Modal_Attention_Preservation_with_Self-Contrastive_Learning_for_Composed_Query-Based_Image_Retrieval.md) |
| Supervised | **Composed Image Retrieval with Text Feedback via Multi-Grained Uncertainty Regularization**                   | Shoes (R@1: 18.41, R@10: 53.63), Fashion200k (R@1: 21.8, R@10: 52.1) | [Github](https://github.com/Monoxide-Chen/uncertainty_retrieval) | [Meta](./paper-meta/Supervised_CIR/aft2024/Composed_Image_Retrieval_with_Text_Feedback_via_Multi-Grained_Uncertainty_Regularization.md)                   |
| Supervised | **FineCIR: Explicit Parsing of Fine-Grained Modification Semantics for Composed Image Retrieval**              | Fine-FashionIQ (R@10: 61.18, R@50: 82.69), Fine-CIRR (Avg: 84.73)    | [Github](https://github.com/SDU-L/FineCIR)                       | [Meta](./paper-meta/Supervised_CIR/aft2024/FineCIR:_Explicit_Parsing_of_Fine-Grained_Modification_Semantics_for_Composed_Image_Retrieval.md)              |
| Zero-Shot  | **Semantic Editing Increment Benefits Zero-Shot Composed Image Retrieval**                                     | CIRCO (mAP@5: 32.46, mAP@10: 33.77)                                  | [Github](https://github.com/yzy-bupt/SEIZE)                      | [Meta](./paper-meta/Zero-Shot_CIR/aft2024/Semantic_Editing_Increment_Benefits_Zero-Shot_Composed_Image_Retrieval.md)                                      |

## 补充说明

- **“-”** 表示在原论文的提取表格中未直接提供该指标或采用了不同标准。
- 部分论文可能只侧重了特定的数据集（如 CMAP 侧重于 Fashion 领域），因此没有在 CIRR 上进行测试。
- FineCIR 提出了全新的细粒度数据集 (Fine-FashionIQ, Fine-CIRR)，具有独立评测标准，已收录于 Others 分类中。

## next step

基于当前已在跑的 baseline：

- CaLa
- ConText-CIR
- Bi-Blip4CIR

结合 `paper-meta` 中剩余候选的 **开源情况、复现难度、资源需求、指标强度、与现有方法的互补性**，建议后续优先级如下。

### 优先级 Top 5

| Rank | Paper Title                                                                                          | Recommendation                    | Reason                                                                                                                                               |
| :--- | :--------------------------------------------------------------------------------------------------- | :-------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1    | **DetailFusion: A Dual-branch Framework with Detail Enhancement for Composed Image Retrieval**       | **Next baseline to run**          | 在 CIRR / FashionIQ 上指标最强，和当前已跑方法同属主线监督式 CIR，横向对比最直接；方法路线偏细节增强，和 CaLa / ConText-CIR / Bi-Blip4CIR 互补性强。 |
| 2    | **FineCIR: Explicit Parsing of Fine-Grained Modification Semantics for Composed Image Retrieval**    | Strong backup choice              | 明确开源，方法新，适合补 fine-grained CIR 方向；但依赖场景图解析和额外细粒度数据流程，工程复杂度较高。                                               |
| 3    | **Improving Composed Image Retrieval via Contrastive Learning with Scaling Positives and Negatives** | Good complementary baseline       | 开源且方法有代表性，属于数据扩增 + 对比学习增强路线，可作为通用增强型 baseline；但需要处理自动生成正样本和大规模负样本。                             |
| 4    | **SPIRIT: Style-guided Patch Interaction for Fashion Image Retrieval with Text Feedback**            | Lower-risk supplementary baseline | 明确开源，偏 fashion/style 路线，复现风险相对可控；但整体代表性和强度略弱于前三。                                                                    |
| 5    | **Simple but Effective Raw-Data Level Multimodal Fusion for Composed Image Retrieval**               | Optional                          | 思路有区分度，但依赖 BLIP-2 caption 与外部关键词抽取流程，复现链条不够干净，不建议优先。                                                             |

### Recommended order

1. **DetailFusion**
2. **FineCIR**
3. **SPN4CIR**
4. **SPIRIT**
5. **DQU-CIR**

### Final recommendation

- 默认下一个跑：**DetailFusion**
- 如果更重视“明确开源 + 稳妥复现”，则下一个改为：**FineCIR**
